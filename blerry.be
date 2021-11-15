# --------- USER INPUT ---------
var device_map = {'A4C138AAAAAA': {'alias': 'trial_govee5075', 'model': 'GVH5075'},
                  'A4C138BBBBBB': {'alias': 'other_govee5075', 'model': 'GVH5075'}}
var base_topic = 'tele/tasmota_blerry'
var sensor_retain = false
var publish_attributes = true
var publish_json = true

# ----------- HELPERS ----------
def TaylorLog(x)
  var z = (x + 1.0)/(x - 1.0)
  var step = ((x - 1.0) * (x - 1.0)) / ((x + 1.0) * (x + 1.0))
  var totalValue = 0.0
  var powe = 1.0
  for count:0..9
    z = step*z
    totalValue = totalValue + (1.0 / powe) * z
    powe = powe + 2.0
  end
  return 2.0*totalValue
end

def CalcTempHumToDew(t, h)
  var gamma = TaylorLog(h / 100.0) + 17.62 * t / (243.5 + t)
  return (243.5 * gamma / (17.62 - gamma))
end

# ----------- BLERRY -----------
import string
var device_topic = ''

# GVH5075: Govee Temp and Humidity Sensor
def handle_GVH5075(value, trigger, msg)
    var p = bytes(value['p'])
    var i = 0
    var adv_len = 0
    var adv_data = bytes('')
    var adv_type = 0
    while i < size(p)
      adv_len = p.get(i,1)
      adv_type = p.get(i+1,1)
      adv_data = p[i+2..i+adv_len]
      if adv_type == 0xFF
        var basenum = (bytes('00') + adv_data[3..5]).get(0,-4)
        var temp = 0
        var humi = 0
        if basenum >= 0x800000
            temp = (0x800000 - basenum)/10000.0
            humi = ((basenum - 0x800000) % 1000)/10.0
        else
            temp = basenum/10000.0
            humi = (basenum % 1000)/10.0
        end
        var batt = adv_data.get(6,1)
        var dewp = CalcTempHumToDew(temp, humi)
        var this_topic = base_topic + '/' + device_map[value['mac']]['alias']
        if publish_attributes
          tasmota.publish(this_topic + '/Time', tasmota.time_str(tasmota.rtc()['local']), sensor_retain)
          tasmota.publish(this_topic + '/alias', device_map[value['mac']]['alias'], sensor_retain)
          tasmota.publish(this_topic + '/mac', value['mac'], sensor_retain)
          tasmota.publish(this_topic + '/via_device', device_topic, sensor_retain)
          tasmota.publish(this_topic + '/Temperature', string.format('%.1f', temp), sensor_retain)
          tasmota.publish(this_topic + '/Humidity', string.format('%.1f', humi), sensor_retain)
          tasmota.publish(this_topic + '/DewPoint', string.format('%.1f', dewp), sensor_retain)
          tasmota.publish(this_topic + '/Battery', string.format('%d', batt), sensor_retain)
          tasmota.publish(this_topic + '/RSSI', string.format('%d', value['RSSI']), sensor_retain)
        end
        if publish_json
          var state_payload = string.format('{\"Time\":\"%s\",\"alias\":\"%s\",\"mac\":\"%s\",\"via_device\":\"%s\",\"Temperature\":\"%.1f\",\"Humidity\":\"%.1f\",\"DewPoint\":\"%.1f\",\"Battery\":\"%d\",\"RSSI\":\"%d\"}',tasmota.time_str(tasmota.rtc()['local']),device_map[value['mac']]['alias'],value['mac'],device_topic,temp,humi,dewp,batt,value['RSSI'], sensor_retain)
          tasmota.publish(this_topic, state_payload)
        end
      end
      i = i + adv_len + 1
    end
end

# Register Aliases with Tasmota and Register Handle Functions
var mac_to_handle = {}
for mac:device_map.keys()
    var item = device_map[mac]
    tasmota.cmd(string.format('BLEAlias %s=%s', mac, item['alias']))
    if item['model'] == 'GVH5075'
        mac_to_handle[mac] = handle_GVH5075
    end
    # todo: HA discovery maybe
end

# Get this Device's topic for VIA_DEVICE publish
def Status_callback(value, trigger, msg)
  device_topic = value['Topic']
end
tasmota.add_rule('Status', Status_callback)
tasmota.cmd('Status')

# Enable BLEDetails for All Aliased Devices and Make Rule
tasmota.cmd('BLEDetails4')
def DetailsBLE_callback(value, trigger, msg)
  try
    var f_handle = mac_to_handle[value['mac']]
    f_handle(value, trigger, msg)
  except 'key_error'
    # log('No handle function for specified mac', value['mac']) # commented bc annoying
  end
end
tasmota.add_rule("DetailsBLE", DetailsBLE_callback) # https://github.com/arendst/Tasmota/pull/13671 was merged
# tasmota.add_rule("details", DetailsBLE_callback) # DetailsBLE if https://github.com/arendst/Tasmota/pull/13671 is accepted