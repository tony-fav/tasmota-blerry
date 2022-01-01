# Xiaomi Sensor on ATC firmware with "mi-like" advertisement
def handle_ATCmi(value, trigger, msg)
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
      if (adv_type == 0x16) && (adv_len == 0x15) && (adv_data[0..1] == bytes('95FE'))
        var last_data = this_device['last_p']
        if last_data == bytes('')
          last_data = [0, -1, -1]
          device_config[value['mac']]['last_p'] = last_data
        end
        var this_data = [last_data[0], last_data[1], last_data[2]]
        if (adv_data[13] == 0x0D) && (adv_data[15] == 0x04) # temp and humi
          this_data[0] = adv_data.geti(16,2) # signed
          this_data[1] = adv_data.get(18,2)
        elif (adv_data[13] == 0x0A) && (adv_data[15] == 0x01) # battery
          this_data[2] = adv_data[16]
        else
          return 0
        end
        if this_data == last_data
          return 0
        else
          device_config[value['mac']]['last_p'] = this_data
        end
        if (this_data[1] < 0) || (this_data[2] < 0)
          return 0
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
        output_map['Temperature'] = this_data[0]/10.0
        output_map['Humidity'] = this_data[1]/10.0
        output_map['Battery'] = this_data[2]
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
device_handles['ATCmi'] = handle_ATCmi
require_active['ATCmi'] = false