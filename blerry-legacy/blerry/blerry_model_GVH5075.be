# GVH5075: Govee Temp and Humidity Sensor
def handle_GVH5075(value, trigger, msg)
  if trigger == details_trigger
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
      if (adv_type == 0xFF) && (adv_len == 9)
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
        var dev_type = adv_data.get(0,-2)
        var basenum = 0x00000000
        if dev_type == 0x88EC # GVH5075/GVH5072
          basenum = (bytes('00') + adv_data[3..5]).get(0,-4)
          output_map['Battery'] = adv_data.get(6,1)
        elif dev_type == 0x0100 # GVH5101/GVH5102
          basenum = (bytes('00') + adv_data[4..6]).get(0,-4)
          output_map['Battery'] = adv_data.get(7,1)
        end
        if basenum >= 0x800000
          output_map['Temperature'] = (basenum-0x800000)/-10000.0
          output_map['Humidity'] = ((basenum-0x800000) % 1000)/10.0
        else
          output_map['Temperature'] = basenum/10000.0
          output_map['Humidity'] = (basenum % 1000)/10.0
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
      i = i + adv_len + 1
    end
  end
end

# map function into handles array
device_handles['GVH5075'] = handle_GVH5075
require_active['GVH5075'] = false

device_handles['GVH5072'] = handle_GVH5075
require_active['GVH5072'] = false

device_handles['GVH5101'] = handle_GVH5075
require_active['GVH5101'] = false

device_handles['GVH5102'] = handle_GVH5075
require_active['GVH5102'] = false
