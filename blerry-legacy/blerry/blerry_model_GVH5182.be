# 22:12:56.826 RSL: BLE = {"DetailsBLE":{"mac":"C33130305011/1","a":"govee5182meats","RSSI":-24,"p":"0201060303518214FF30501101000101E4018308981CE88208981BC7"}}
# 02 0106 03 035182 14 FF 30501101000101E4018308981CE88208981BC7
def handle_GVH5182(value, trigger, msg)
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
        if (adv_type == 0xFF) && (adv_len == 0x14)
            var this_data = [adv_data[7] & 0x7F, adv_data.get(10, -2), adv_data.get(12, -2), adv_data.geti(15, -2), adv_data.geti(17, -2)]
            var last_data = this_device['last_p']
            if (last_data != bytes('')) && (this_data == last_data)
              return 0
            end
            device_config[value['mac']]['last_p'] = this_data
            if this_device['discovery'] && !this_device['done_disc']
              publish_sensor_discovery(value['mac'], 'Temperature_1', 'temperature', '°C')
              publish_sensor_discovery(value['mac'], 'Temperature_1_Target', 'temperature', '°C')
              publish_sensor_discovery(value['mac'], 'Temperature_2', 'temperature', '°C')
              publish_sensor_discovery(value['mac'], 'Temperature_2_Target', 'temperature', '°C')
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
            output_map['Battery'] = this_data[0]
            if this_data[1] == 65535
              output_map['Temperature_1'] = 'unavailable'
            else
              output_map['Temperature_1'] = round(this_data[1]/100.0, this_device['temp_precision'])
            end
            if this_data[2] == 65535
              output_map['Temperature_1_Target'] = 'unavailable'
            else
              output_map['Temperature_1_Target'] = round(this_data[2]/100.0, this_device['temp_precision'])
            end
            if this_data[3] == 65535
              output_map['Temperature_2'] = 'unavailable'
            else
              output_map['Temperature_2'] = round(this_data[3]/100.0, this_device['temp_precision'])
            end
            if this_data[4] == 65535
              output_map['Temperature_2_Target'] = 'unavailable'
            else
              output_map['Temperature_2_Target'] = round(this_data[4]/100.0, this_device['temp_precision'])
            end
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
  device_handles['GVH5182'] = handle_GVH5182
  require_active['GVH5182'] = false