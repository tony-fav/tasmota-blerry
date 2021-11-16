# --------- USER INPUT ---------
var device_map = {'A4C138AAAAAA': {'alias': 'trial_govee5075', 'model': 'GVH5075', 'discovery': true, 'use_lwt': false},
                  'A4C138BBBBBB': {'alias': 'other_govee5075', 'model': 'GVH5075', 'discovery': false},
                  'A4C138CCCCCC': {'alias': 'trial_ATCpvvx', 'model': 'ATCpvvx', 'discovery': true, 'use_lwt': true}}
var base_topic = 'tele/tasmota_blerry'
var sensor_retain = false
var publish_attributes = true

# ----------- IMPORTS ----------
import math
import string
import json

# ----------- HELPERS ----------
def get_dewpoint(t, h)
  var gamma = math.log(h / 100.0) + 17.62 * t / (243.5 + t)
  return (243.5 * gamma / (17.62 - gamma))
end

# ----------- BLERRY -----------
var discovery_retain = true # only false when testing
var last_message = {}
var done_extra_discovery = {}

# Get this Device's topic for VIA_DEVICE publish
var device_topic = ''
def Status_callback(value, trigger, msg)
  device_topic = value['Topic']
end
tasmota.add_rule('Status', Status_callback)
tasmota.cmd('Status')
var hostname = ''
def Status5_callback(value, trigger, msg)
  hostname = value['Hostname']
end
tasmota.add_rule('StatusNet', Status5_callback)
tasmota.cmd('Status 5')

def publish_sensor_discovery(mac, prop, dclass, unitm)
  var item = device_map[mac]
  var prefix = '{'
  if item['use_lwt']
    prefix = prefix + string.format('"avty_t\": \"tele/%s/LWT\",\"pl_avail\": \"Online\",\"pl_not_avail\": \"Offline\",', device_topic)
  else
    prefix = prefix + '\"avty\": [],'
  end
  prefix = prefix + string.format('\"dev\":{\"ids\":[\"blerry_%s\"],\"name\":\"%s\",\"mf\":\"blerry\",\"mdl\":\"%s\",\"via_device\":\"%s\"},', item['alias'], item['alias'], item['model'], hostname)
  prefix = prefix + string.format('\"exp_aft\": 600,\"json_attr_t\": \"%s/%s\",\"stat_t\": \"%s/%s\",', base_topic, item['alias'], base_topic, item['alias'])
  tasmota.publish(string.format('homeassistant/sensor/blerry_%s/%s/config', item['alias'], prop), prefix + string.format('\"dev_cla\": \"%s\",\"unit_of_meas\": \"%s\",\"name\": \"%s %s\",\"uniq_id\": \"blerry_%s_%s\",\"val_tpl\": \"{{ value_json.%s }}\"}', dclass, unitm, item['alias'], prop, item['alias'], prop, prop), discovery_retain)
end

def publish_binary_sensor_discovery(mac, prop, dclass)
  var item = device_map[mac]
  var prefix = '{'
  if item['use_lwt']
    prefix = prefix + string.format('"avty_t\": \"tele/%s/LWT\",\"pl_avail\": \"Online\",\"pl_not_avail\": \"Offline\",', device_topic)
  else
    prefix = prefix + '\"avty\": [],'
  end
  prefix = prefix + string.format('\"dev\":{\"ids\":[\"blerry_%s\"],\"name\":\"%s\",\"mf\":\"blerry\",\"mdl\":\"%s\",\"via_device\":\"%s\"},', item['alias'], item['alias'], item['model'], hostname)
  prefix = prefix + string.format('\"exp_aft\": 600,\"json_attr_t\": \"%s/%s\",\"stat_t\": \"%s/%s\",', base_topic, item['alias'], base_topic, item['alias'])
  if dclass != 'none'
    prefix = prefix + string.format('\"dev_cla\": \"%s\",', dclass)
  end
  tasmota.publish(string.format('homeassistant/binary_sensor/blerry_%s/%s/config', item['alias'], prop), prefix + string.format('\"name\": \"%s %s\",\"uniq_id\": \"blerry_%s_%s\",\"val_tpl\": \"{{ value_json.%s }}\"}', item['alias'], prop, item['alias'], prop, prop), discovery_retain)
end

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
        var output_map = {}
        output_map['Time'] = tasmota.time_str(tasmota.rtc()['local'])
        output_map['alias'] = device_map[value['mac']]['alias']
        output_map['mac'] = value['mac']
        output_map['via_device'] = device_topic
        output_map['RSSI'] = value['RSSI']
        var basenum = (bytes('00') + adv_data[3..5]).get(0,-4)
        if basenum >= 0x800000
          output_map['Temperature'] = (0x800000 - basenum)/10000.0
          output_map['Humidity'] = ((basenum - 0x800000) % 1000)/10.0
        else
          output_map['Temperature'] = basenum/10000.0
          output_map['Humidity'] = (basenum % 1000)/10.0
        end
        output_map['Battery'] = adv_data.get(6,1)
        output_map['DewPoint'] = get_dewpoint(output_map['Temperature'], output_map['Humidity'])
        var this_topic = base_topic + '/' + device_map[value['mac']]['alias']
        tasmota.publish(this_topic, json.dump(output_map), sensor_retain)
        if publish_attributes
          for output_key:output_map.keys()
            tasmota.publish(this_topic + '/' + output_key, string.format('%s', output_map[output_key]), sensor_retain)
          end
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
        # todo: don't readvert if only thing new is the counter
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
        var output_map = {}
        output_map['Time'] = tasmota.time_str(tasmota.rtc()['local'])
        output_map['alias'] = device_map[value['mac']]['alias']
        output_map['mac'] = value['mac']
        output_map['via_device'] = device_topic
        output_map['RSSI'] = value['RSSI']
        if adv_len == 16
          output_map['Temperature'] = adv_data.geti(8,-2)/10.0
          output_map['Humidity'] = adv_data.get(10,1)
          output_map['Battery'] = adv_data.get(11,1)
          output_map['Battery_Voltage'] = adv_data.get(12,-2)/1000.0
        elif adv_len == 18
            is_pvvx = true
            if device_map[value['mac']]['discovery']
              if !done_extra_discovery[value['mac']]
                publish_binary_sensor_discovery(value['mac'], 'GPIO_PA6', 'none')
                publish_binary_sensor_discovery(value['mac'], 'GPIO_PA5', 'none')
                publish_binary_sensor_discovery(value['mac'], 'Triggered_by_Temperature', 'none')
                publish_binary_sensor_discovery(value['mac'], 'Triggered_by_Humidity', 'none')
                done_extra_discovery[value['mac']] = true
              end
            end
            output_map['Temperature'] = adv_data.geti(8,2)/100.0
            output_map['Humidity'] = adv_data.get(10,2)/100.0
            output_map['Battery_Voltage'] = adv_data.get(12,2)/1000.0
            output_map['Battery'] = adv_data.get(14,1)
            output_map['Count'] = adv_data.get(15,1)
            output_map['Flag'] = adv_data.get(16,1)
            if output_map['Flag'] & 1
              output_map['GPIO_PA6'] = 'ON'
            else
              output_map['GPIO_PA6'] = 'OFF'
            end
            if output_map['Flag'] & 2
              output_map['GPIO_PA5'] = 'ON'
            else
              output_map['GPIO_PA5'] = 'OFF'
            end
            if output_map['Flag'] & 4
              output_map['Triggered_by_Temperature'] = 'ON'
            else
              output_map['Triggered_by_Temperature'] = 'OFF'
            end
            if output_map['Flag'] & 8
              output_map['Triggered_by_Humidity'] = 'ON'
            else
              output_map['Triggered_by_Humidity'] = 'OFF'
            end
        end
        output_map['DewPoint'] = get_dewpoint(output_map['Temperature'], output_map['Humidity'])
        var this_topic = base_topic + '/' + device_map[value['mac']]['alias']
        # todo: additional discovery for pvvx flag data
        tasmota.publish(this_topic, json.dump(output_map), sensor_retain)
        if publish_attributes
          for output_key:output_map.keys()
            tasmota.publish(this_topic + '/' + output_key, string.format('%s', output_map[output_key]), sensor_retain)
          end
        end
      end
    end
    i = i + adv_len + 1
  end
end

# Register Aliases with Tasmota and Register Handle Functions, do HA MQTT Discovery
var mac_to_handle = {}
for mac:device_map.keys()
    var item = device_map[mac]
    tasmota.cmd(string.format('BLEAlias %s=%s', mac, item['alias']))
    if item['model'] == 'GVH5075'
      mac_to_handle[mac] = handle_GVH5075
      if item['discovery']
        publish_sensor_discovery(mac, 'Temperature', 'temperature', '°C')
        publish_sensor_discovery(mac, 'Humidity', 'humidity', '%')
        publish_sensor_discovery(mac, 'DewPoint', 'temperature', '°C')
        publish_sensor_discovery(mac, 'Battery', 'battery', '%')
        publish_sensor_discovery(mac, 'RSSI', 'signal_strength', 'dB')
      end
    elif item['model'] == 'ATCpvvx'
      mac_to_handle[mac] = handle_ATCpvvx
      if item['discovery']
        publish_sensor_discovery(mac, 'Temperature', 'temperature', '°C')
        publish_sensor_discovery(mac, 'Humidity', 'humidity', '%')
        publish_sensor_discovery(mac, 'DewPoint', 'temperature', '°C')
        publish_sensor_discovery(mac, 'Battery', 'battery', '%')
        publish_sensor_discovery(mac, 'Battery_Voltage', 'voltage', 'V')
        publish_sensor_discovery(mac, 'RSSI', 'signal_strength', 'dB')
        done_extra_discovery[mac] = false # for pvvx if it is pvvx
      end
    end
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