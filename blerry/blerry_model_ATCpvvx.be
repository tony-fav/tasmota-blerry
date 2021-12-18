
# ATC or pvvx
def handle_ATCpvvx(value, trigger, msg)
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

# map function into handles array
device_handles['ATCpvvx'] = handle_ATCpvvx
require_active['ATCpvvx'] = false

device_handles['ATC'] = handle_ATCpvvx
require_active['ATC'] = false

device_handles['pvvx'] = handle_ATCpvvx
require_active['pvvx'] = false