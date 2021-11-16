# --------- USER INPUT ---------
var device_map = {'A4C138AAAAAA': {'alias': 'trial_govee5075', 'model': 'GVH5075', 'discovery': false},
                  'A4C138BBBBBB': {'alias': 'trial_govee5075', 'model': 'GVH5075', 'discovery': true, 'use_lwt': false},
                  'A4C138CCCCCC': {'alias': 'trial_ATCpvvx', 'model': 'ATCpvvx', 'discovery': true, 'use_lwt': true}}
var base_topic = 'tele/tasmota_blerry'
var sensor_retain = false
var publish_attributes = true

# ----------- HELPERS ----------
import math
def get_dewpoint(t, h)
  var gamma = math.log(h / 100.0) + 17.62 * t / (243.5 + t)
  return (243.5 * gamma / (17.62 - gamma))
end

# ----------- BLERRY -----------
import string
var last_message = {}
var done_extra_discovery = {}

# Get this Device's topic for VIA_DEVICE publish
var device_topic = ''
def Status_callback(value, trigger, msg)
  device_topic = value['Topic']
end
tasmota.add_rule('Status', Status_callback)
tasmota.cmd('Status')

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
        var last_data = bytes('')
        try
          last_data = last_message[value['mac']]
        except 'key_error'
          last_data = bytes('')
        end
        if adv_data == last_data
          return 0
        else
          last_message[value['mac']] = adv_data
        end
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
        var dewp = get_dewpoint(temp, humi)
        var this_topic = base_topic + '/' + device_map[value['mac']]['alias']
        var state_payload = string.format('{\"Time\":\"%s\",\"alias\":\"%s\",\"mac\":\"%s\",\"via_device\":\"%s\",\"Temperature\":\"%.1f\",\"Humidity\":\"%.1f\",\"DewPoint\":\"%.1f\",\"Battery\":\"%d\",\"RSSI\":\"%d\"}',tasmota.time_str(tasmota.rtc()['local']),device_map[value['mac']]['alias'],value['mac'],device_topic,temp,humi,dewp,batt,value['RSSI'])
        tasmota.publish(this_topic, state_payload, sensor_retain)
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
      end
      i = i + adv_len + 1
    end
end

# ATC or pvvx
def handle_ATCpvvx(value, trigger, msg)
  var p = bytes(value['p'])
  var i = 0
  var adv_len = 0
  var adv_data = bytes('')
  var adv_type = 0
  var is_pvvx = false
  while i < size(p)
    adv_len = p.get(i,1)
    adv_type = p.get(i+1,1)
    adv_data = p[i+2..i+adv_len]
    if adv_type == 0x16 # Service Data 16-bit UUID, used by pvvx and ATC advert
      if adv_data[0..1] == bytes('1A18') # little endian of 0x181A
        var last_data = bytes('')
        try
          last_data = last_message[value['mac']]
        except 'key_error'
          last_data = bytes('')
        end
        if adv_data == last_data
          return 0
        else
          last_message[value['mac']] = adv_data
        end
        var temp = 0
        var humi = 0
        var batt = 0
        var volt = 0
        var flag = 0
        if adv_len == 16
            temp = adv_data.geti(8,-2)/10.0
            humi = adv_data.get(10,1)
            batt = adv_data.get(11,1)
            volt = adv_data.get(12,-2)/1000.0
        elif adv_len == 18
            is_pvvx = true
            temp = adv_data.geti(8,2)/100.0
            humi = adv_data.get(10,2)/100.0
            volt = adv_data.get(12,2)/1000.0
            batt = adv_data.get(14,1)
            # meas_count = adv_data.get(15,1)
            flag = adv_data.get(16,1)
        end
        var dewp = get_dewpoint(temp, humi)
        var this_topic = base_topic + '/' + device_map[value['mac']]['alias']
        var state_payload = ''
        if is_pvvx
          state_payload = string.format('{\"Time\":\"%s\",\"alias\":\"%s\",\"mac\":\"%s\",\"via_device\":\"%s\",\"Temperature\":\"%.1f\",\"Humidity\":\"%.1f\",\"DewPoint\":\"%.1f\",\"Battery\":\"%d\",\"RSSI\":\"%d\"}',tasmota.time_str(tasmota.rtc()['local']),device_map[value['mac']]['alias'],value['mac'],device_topic,temp,humi,dewp,batt,value['RSSI'])
        else
          state_payload = string.format('{\"Time\":\"%s\",\"alias\":\"%s\",\"mac\":\"%s\",\"via_device\":\"%s\",\"Temperature\":\"%.1f\",\"Humidity\":\"%.1f\",\"DewPoint\":\"%.1f\",\"Battery\":\"%d\",\"RSSI\":\"%d\",\"flag\":\"%d\"}',tasmota.time_str(tasmota.rtc()['local']),device_map[value['mac']]['alias'],value['mac'],device_topic,temp,humi,dewp,batt,value['RSSI'],flag)
        end
        tasmota.publish(this_topic, state_payload, sensor_retain)
        if publish_attributes
          tasmota.publish(this_topic + '/Time', tasmota.time_str(tasmota.rtc()['local']), sensor_retain)
          tasmota.publish(this_topic + '/alias', device_map[value['mac']]['alias'], sensor_retain)
          tasmota.publish(this_topic + '/mac', value['mac'], sensor_retain)
          tasmota.publish(this_topic + '/via_device', device_topic, sensor_retain)
          tasmota.publish(this_topic + '/Temperature', string.format('%.1f', temp), sensor_retain)
          tasmota.publish(this_topic + '/Humidity', string.format('%.1f', humi), sensor_retain)
          tasmota.publish(this_topic + '/DewPoint', string.format('%.1f', dewp), sensor_retain)
          tasmota.publish(this_topic + '/Battery', string.format('%d', batt), sensor_retain)
          tasmota.publish(this_topic + '/BatteryV', string.format('%.2f', volt), sensor_retain)
          tasmota.publish(this_topic + '/RSSI', string.format('%d', value['RSSI']), sensor_retain)
          if is_pvvx
            tasmota.publish(this_topic + '/flag', string.format('%d', flag), sensor_retain)
          end
        end
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
      if item['discovery']
        var disc_payload_prefix = '{'
        if item['use_lwt']
          disc_payload_prefix = disc_payload_prefix + string.format('"avty_t\": \"tele/%s/LWT\",\"pl_avail\": \"Online\",\"pl_not_avail\": \"Offline\",', device_topic)
        else
          disc_payload_prefix = disc_payload_prefix + '\"avty\": [],'
        end
        disc_payload_prefix = disc_payload_prefix + string.format('\"dev\":{\"ids\":[\"blerry_%s\"],\"name\":\"%s\",\"mf\":\"blerry\",\"mdl\":\"%s\",\"via_device\":\"%s\"},', item['alias'], item['alias'], item['model'], device_topic)
        disc_payload_prefix = disc_payload_prefix + string.format('\"exp_aft\": 600,\"json_attr_t\": \"%s/%s\",\"stat_t\": \"%s/%s\",', base_topic, item['alias'], base_topic, item['alias'])
        tasmota.publish(string.format('homeassistant/sensor/blerry_%s/Temperature/config', item['alias']), disc_payload_prefix + string.format('\"dev_cla\": \"temperature\",\"unit_of_meas\": \"°C\",\"name\": \"%s Temperature\",\"uniq_id\": \"blerry_%s_Temperature\",\"val_tpl\": \"{{ value_json.Temperature }}\"}', item['alias'], item['alias']))
        tasmota.publish(string.format('homeassistant/sensor/blerry_%s/Humidity/config', item['alias']), disc_payload_prefix + string.format('\"dev_cla\": \"humidity\",\"unit_of_meas\": \"%%\",\"name\": \"%s Humidity\",\"uniq_id\": \"blerry_%s_Humidity\",\"val_tpl\": \"{{ value_json.Humidity }}\"}', item['alias'], item['alias']))
      end
    elif item['model'] == 'ATCpvvx'
      mac_to_handle[mac] = handle_ATCpvvx
      if item['discovery']
        var disc_payload_prefix = '{'
        if item['use_lwt']
          disc_payload_prefix = disc_payload_prefix + string.format('"avty_t\": \"tele/%s/LWT\",\"pl_avail\": \"Online\",\"pl_not_avail\": \"Offline\",', device_topic)
        else
          disc_payload_prefix = disc_payload_prefix + '\"avty\": [],'
        end
        disc_payload_prefix = disc_payload_prefix + string.format('\"dev\":{\"ids\":[\"blerry_%s\"],\"name\":\"%s\",\"mf\":\"blerry\",\"mdl\":\"%s\",\"via_device\":\"%s\"},', item['alias'], item['alias'], item['model'], device_topic)
        disc_payload_prefix = disc_payload_prefix + string.format('\"exp_aft\": 600,\"json_attr_t\": \"%s/%s\",\"stat_t\": \"%s/%s\",', base_topic, item['alias'], base_topic, item['alias'])
        tasmota.publish(string.format('homeassistant/sensor/blerry_%s/Temperature/config', item['alias']), disc_payload_prefix + string.format('\"dev_cla\": \"temperature\",\"unit_of_meas\": \"°C\",\"name\": \"%s Temperature\",\"uniq_id\": \"blerry_%s_Temperature\",\"val_tpl\": \"{{ value_json.Temperature }}\"}', item['alias'], item['alias']))
        tasmota.publish(string.format('homeassistant/sensor/blerry_%s/Humidity/config', item['alias']), disc_payload_prefix + string.format('\"dev_cla\": \"humidity\",\"unit_of_meas\": \"%%\",\"name\": \"%s Humidity\",\"uniq_id\": \"blerry_%s_Humidity\",\"val_tpl\": \"{{ value_json.Humidity }}\"}', item['alias'], item['alias']))
      end
    end
    # todo: HA discovery maybe
end

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