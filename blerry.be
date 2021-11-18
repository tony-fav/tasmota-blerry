# --------- USER INPUT ---------
var user_config = {'A4C138AAAAAA': {'alias': 'trial_govee5075', 'model': 'GVH5075', 'discovery': true},
                   'A4C138BBBBBB': {'alias': 'other_govee5075', 'model': 'GVH5075', 'via_pubs': false},
                   'A4C138CCCCCC': {'alias': 'trial_ATCpvvx', 'model': 'ATCpvvx', 'discovery': true, 'use_lwt': true}}
var base_topic = 'tele/tasmota_blerry'

# ----------- IMPORTS ----------
import math
import string
import json

# ----------- DEFAULT ----------
var default_config = {'model': 'ATCpvvx',            # Must match 'ATCpvvx', 'GVH5075', or 'IBSTH2'
                      'discovery': false,            # HA MQTT Discovery
                      'use_lwt': false,              # use receiving device's LWT as LWT for BLE device
                      'via_pubs': true,              # publish attributes like "Time_via_%topic%" and "RSSI_via_%topic%"
                      'sensor_retain': false,        # retain publication of data
                      'publish_attributes': true,    # publish attributes to individual topics in addition to JSON payload
                      'temp_precision': 2,           # digits of precision for temperature
                      'humi_precision': 1,           # digits of precision for humidity
                      'last_p': bytes(''),           # DO NOT CHANGE
                      'done_disc': false,            # DO NOT CHANGE
                      'done_extra_disc': false}      # DO NOT CHANGE
var device_config = {}

# ----------- HELPERS ----------
def round(x, p)
  return math.ceil(math.pow(10.0, p)*x)/math.pow(10.0, p)
end
def get_dewpoint(t, h) # temp, humidity, precision
  var gamma = math.log(h / 100.0) + 17.62 * t / (243.5 + t)
  return (243.5 * gamma / (17.62 - gamma))
end

# ----------- BLERRY -----------
var discovery_retain = true # only false when testing

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
  var item = device_config[mac]
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
  var item = device_config[mac]
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
  if trigger == 'DetailsBLE'
    var this_device = device_config[value['mac']]
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
        var last_data = this_device['last_p']
        if adv_data == last_data
          return 0
        else
          device_config[value['mac']]['last_p'] = adv_data
        end
        if this_device['discovery'] && !this_device['done_disc']
          publish_sensor_discovery(value['mac'], 'Temperature', 'temperature', '°C')
          publish_sensor_discovery(value['mac'], 'Humidity', 'humidity', '%')
          publish_sensor_discovery(value['mac'], 'DewPoint', 'temperature', '°C')
          publish_sensor_discovery(value['mac'], 'Battery', 'battery', '%')
          publish_sensor_discovery(value['mac'], 'RSSI', 'signal_strength', 'dB')
          device_config[value['mac']]['done_disc'] = true
        end
        var output_map = {}
        output_map['Time'] = tasmota.time_str(tasmota.rtc()['local'])
        output_map['alias'] = this_device['alias']
        output_map['mac'] = value['mac']
        output_map['via_device'] = device_topic
        output_map['RSSI'] = value['RSSI']
        if this_device['via_pubs']
          output_map['Time_via_' + device_topic] = output_map['Time']
          output_map['RSSI_via_' + device_topic] = output_map['RSSI']
        end
        var basenum = (bytes('00') + adv_data[3..5]).get(0,-4)
        if basenum >= 0x800000
          output_map['Temperature'] = (0x800000 - basenum)/10000.0
          output_map['Humidity'] = ((basenum - 0x800000) % 1000)/10.0
        else
          output_map['Temperature'] = basenum/10000.0
          output_map['Humidity'] = (basenum % 1000)/10.0
        end
        output_map['Battery'] = adv_data.get(6,1)
        output_map['DewPoint'] = round(get_dewpoint(output_map['Temperature'], output_map['Humidity']), this_device['temp_precision'])
        output_map['Temperature'] = round(output_map['Temperature'], this_device['temp_precision'])
        output_map['Humidity'] = round(output_map['Humidity'], this_device['humi_precision'])
        var this_topic = base_topic + '/' + this_device['alias']
        tasmota.publish(this_topic, json.dump(output_map), this_device['sensor_retain'])
        if this_device['publish_attributes']
          for output_key:output_map.keys()
            tasmota.publish(this_topic + '/' + output_key, string.format('%s', output_map[output_key]), this_device['sensor_retain'])
          end
        end
      end
      i = i + adv_len + 1
    end
  end
end

# ATC or pvvx
def handle_ATCpvvx(value, trigger, msg)
  if trigger == 'DetailsBLE'
    var this_device = device_config[value['mac']]
    var p = bytes(value['p'])
    var i = 0
    var adv_len = 0
    var adv_data = bytes('')
    var adv_type = 0
    while i < size(p)
      adv_len = p.get(i,1)
      adv_type = p.get(i+1,1)
      adv_data = p[i+2..i+adv_len]
      if adv_type == 0x16 # Service Data 16-bit UUID, used by pvvx and ATC advert
        if adv_data[0..1] == bytes('1A18') # little endian of 0x181A
          var last_data = this_device['last_p']
          if (size(last_data) == 18) && (adv_len == 18)  # use this to ignore re-processing of "same data, new counter"
            last_data[15] = adv_data[15]
          end
          if adv_data == last_data
            return 0
          else
            device_config[value['mac']]['last_p'] = adv_data
          end
          if this_device['discovery'] && !this_device['done_disc']
            publish_sensor_discovery(value['mac'], 'Temperature', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Humidity', 'humidity', '%')
            publish_sensor_discovery(value['mac'], 'DewPoint', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Battery', 'battery', '%')
            publish_sensor_discovery(value['mac'], 'Battery_Voltage', 'voltage', 'V')
            publish_sensor_discovery(value['mac'], 'RSSI', 'signal_strength', 'dB')
            device_config[value['mac']]['done_disc'] = true
          end
          var output_map = {}
          output_map['Time'] = tasmota.time_str(tasmota.rtc()['local'])
          output_map['alias'] = this_device['alias']
          output_map['mac'] = value['mac']
          output_map['via_device'] = device_topic
          output_map['RSSI'] = value['RSSI']
          if this_device['via_pubs']
            output_map['Time_via_' + device_topic] = output_map['Time']
            output_map['RSSI_via_' + device_topic] = output_map['RSSI']
          end
          if adv_len == 16
            output_map['Temperature'] = adv_data.geti(8,-2)/10.0
            output_map['Humidity'] = adv_data.get(10,1)
            output_map['Battery'] = adv_data.get(11,1)
            output_map['Battery_Voltage'] = adv_data.get(12,-2)/1000.0
          elif adv_len == 18
              if this_device['discovery'] && !this_device['done_extra_disc']
                publish_binary_sensor_discovery(value['mac'], 'GPIO_PA6', 'none')
                publish_binary_sensor_discovery(value['mac'], 'GPIO_PA5', 'none')
                publish_binary_sensor_discovery(value['mac'], 'Triggered_by_Temperature', 'none')
                publish_binary_sensor_discovery(value['mac'], 'Triggered_by_Humidity', 'none')
                device_config[value['mac']]['done_extra_disc'] = true
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
          output_map['DewPoint'] = round(get_dewpoint(output_map['Temperature'], output_map['Humidity']), this_device['temp_precision'])
          output_map['Temperature'] = round(output_map['Temperature'], this_device['temp_precision'])
          output_map['Humidity'] = round(output_map['Humidity'], this_device['humi_precision'])
          var this_topic = base_topic + '/' + this_device['alias']
          tasmota.publish(this_topic, json.dump(output_map), this_device['sensor_retain'])
          if this_device['publish_attributes']
            for output_key:output_map.keys()
              tasmota.publish(this_topic + '/' + output_key, string.format('%s', output_map[output_key]), this_device['sensor_retain'])
            end
          end
        end
      end
      i = i + adv_len + 1
    end
  end
end

var device_handles = {'GVH5075': handle_GVH5075, 
                      'ATCpvvx': handle_ATCpvvx}

# Register Aliases with Tasmota and Register Handle Functions, do HA MQTT Discovery
for mac:user_config.keys()
  device_config[mac] = {}
  for item:default_config.keys()
    device_config[mac][item] = default_config[item]
  end
  for item:user_config[mac].keys()
    device_config[mac][item] = user_config[mac][item]
  end
  device_config[mac]['handle'] = device_handles[device_config[mac]['model']]
  tasmota.cmd(string.format('BLEAlias %s=%s', mac, device_config[mac]['alias']))
end

# Enable BLEDetails for All Aliased Devices and Make Rule
tasmota.cmd('BLEDetails4')
def DetailsBLE_callback(value, trigger, msg)
    device_config[value['mac']]['handle'](value, trigger, msg)
end
tasmota.add_rule("DetailsBLE", DetailsBLE_callback) # https://github.com/arendst/Tasmota/pull/13671 was merged
# tasmota.add_rule("details", DetailsBLE_callback) # DetailsBLE if https://github.com/arendst/Tasmota/pull/13671 is accepted