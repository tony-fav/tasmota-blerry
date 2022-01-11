# The 5184 uses a two line method. Probe1/2 are published in one packet.  Probe3/4 in another.  Not always sequential
def handle_GVH5184(value, trigger, msg)
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
        var this_part_data = [adv_data.get(9, -1), adv_data.get(10, -2), adv_data.get(12, -2), adv_data.get(14, -1), adv_data.get(15, -2), adv_data.get(17, -2)]
        var last_full_data = this_device['last_p']
        var this_full_data = [ 0, [-1, 0, 0, 0, 0, 0], [-1, 0, 0, 0, 0, 0], 0 ]
        var seq_num = adv_data.get(8, -1)
        if last_full_data == bytes('')
          last_full_data  = [ -1, [-1, 0, 0, 0, 0, 0], [-1, 0, 0, 0, 0, 0], 0 ]
        else
          this_full_data = last_full_data
        end
        if (this_part_data == last_full_data[seq_num]) && (last_full_data[3] < 31)
          this_full_data[3]=this_full_data[3]+1
          device_config[value['mac']]['last_p'] = this_full_data.copy()
          return 0
        end
        this_full_data[0]= adv_data.get(7, -1)
        this_full_data[3] = 0
        this_full_data[seq_num]=this_part_data.copy()
        device_config[value['mac']]['last_p'] = this_full_data.copy()
        if (this_full_data[1][0] < 0) || (this_full_data[2][0]) < 0
          return 0
        end
        if this_device['discovery'] && !this_device['done_disc']
          for j: 1 .. 4
            publish_binary_sensor_discovery(value['mac'], ('Temperature_'+str(j)+'_Status'), 'plug')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_'+str(j)+'_Alarm', 'heat')
            publish_sensor_discovery(value['mac'], 'Temperature_'+str(j), 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_'+str(j)+'_Target', 'temperature', '°C')
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
        output_map['Battery'] = this_full_data[0] & 0x7F
        for j:1 .. 2
          for k:j-1 .. j
            var probeset = ['OFF', 'OFF']
            var status = this_full_data[j][3+((k-j)*3)]
            var probetemp = this_full_data[j][4+((k-j)*3)]
            var setpoint = this_full_data[j][5+((k-j)*3)]
            if (status & 0x80) >> 7
              probeset[0] = 'ON'              
            end
            if (status & 0x40) >> 6
              probeset[1] = 'ON'
            end
            if probetemp==0xFFFF
              probeset = probeset .. 'unavailable'
            else
              probeset = probeset .. round(probetemp/100.0, this_device['temp_precision'])
            end           
            if setpoint==0xFFFF
              probeset = probeset .. 'unavailable'
            else
              probeset = probeset .. round(setpoint/100.0, this_device['temp_precision'])
            output_map['Temperature_'+str(j+k)+'_Status'] = probeset[0]
            output_map['Temperature_'+str(j+k)+'_Alarm'] = probeset[1]
            output_map['Temperature_'+str(j+k)] = probeset[2]
            output_map['Temperature_'+str(j+k)+'_Target'] = probeset[3]
          end
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
device_handles['GVH5184'] = handle_GVH5184
require_active['GVH5184'] = false
