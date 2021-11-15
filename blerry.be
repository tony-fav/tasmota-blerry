# ------------------------------
# --------- USER INPUT ---------
# ------------------------------
var device_map = {'A4C138AAAAAA': {'alias': 'trial_govee5075', 'model': 'GVH5075'},
                  'A4C138BBBBBB': {'alias': 'other_govee5075', 'model': 'GVH5075'}}
var base_topic = 'tele/tasmota_blerry'
var sensor_retain = false
# ------------------------------
# ------------------------------
# ------------------------------
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
        tasmota.publish(base_topic + '/' + device_map[value['mac']]['alias'] + '/RSSI', string.format('%d', value['RSSI']), sensor_retain)
        tasmota.publish(base_topic + '/' + device_map[value['mac']]['alias'] + '/TEMP', string.format('%f', temp), sensor_retain)
        tasmota.publish(base_topic + '/' + device_map[value['mac']]['alias'] + '/TEMP_F', string.format('%f', 9./5.*temp+32.), sensor_retain)
        tasmota.publish(base_topic + '/' + device_map[value['mac']]['alias'] + '/HUMIDITY', string.format('%f', humi), sensor_retain)
        tasmota.publish(base_topic + '/' + device_map[value['mac']]['alias'] + '/BATTERY', string.format('%f', batt), sensor_retain)
        tasmota.publish(base_topic + '/' + device_map[value['mac']]['alias'] + '/VIA_DEVICE', device_topic, sensor_retain)
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
tasmota.add_rule("details", DetailsBLE_callback) # DetailsBLE if https://github.com/arendst/Tasmota/pull/13671 is accepted