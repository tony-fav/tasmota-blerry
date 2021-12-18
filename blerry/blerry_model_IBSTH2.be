# Inkbird TH1 or TH2 with Temp only or Temp + Humidity
# - Does not report if external sensor is being used
def handle_IBSTH2(value, trigger, msg)
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
      if adv_type == 0xFF
        var last_data = this_device['last_p']
        if (adv_data[0..3] + adv_data[7..7]) == (last_data[0..3] + last_data[7..7])
          return 0
        else
          device_config[value['mac']]['last_p'] = adv_data
        end
        var has_humidity = (adv_data.get(2,2) != 0)
        if this_device['discovery'] && !this_device['done_disc']
          publish_sensor_discovery(value['mac'], 'Temperature', 'temperature', '°C')
          if has_humidity
            publish_sensor_discovery(value['mac'], 'Humidity', 'humidity', '%')
            publish_sensor_discovery(value['mac'], 'DewPoint', 'temperature', '°C')
          end
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
        output_map['Temperature'] = adv_data.geti(0,2)/100.0
        output_map['Battery'] = adv_data.get(7,1)
        if has_humidity
          output_map['Humidity'] = adv_data.get(2,2)/100.0
          output_map['DewPoint'] = round(get_dewpoint(output_map['Temperature'], output_map['Humidity']), this_device['temp_precision'])
          output_map['Humidity'] = round(output_map['Humidity'], this_device['humi_precision'])
        end
        output_map['Temperature'] = round(output_map['Temperature'], this_device['temp_precision'])
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
device_handles['IBSTH1'] = handle_IBSTH2
require_active['IBSTH1'] = true

device_handles['IBSTH2'] = handle_IBSTH2
require_active['IBSTH2'] = true