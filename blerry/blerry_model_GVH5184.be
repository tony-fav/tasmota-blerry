# Currently the 5183 code.  The 5184 uses a two line method. See the ATC_MI driver for methodology.
# Tested as is - and it will pick up data and send.  Formatting is wrong as well but prelimnary works.
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
              # Build this_part_data with battery, probe-a state, probe-a temp, probe-a set, probe-b state, probe-b temp, probe-b set
          var this_part_data = [adv_data.get(7, -1), adv_data.get(9, -1), adv_data.get(10, -2), adv_data.get(12, -2), adv_data.get(14, -1), adv_data.get(15, -2), adv_data.get(17, -2)]
          var last_data = this_device['last_p']
          var this_full_data = [0, -1, -1, 0, 0, 0, 0, -1, -1, 0, 0, 0, 0]
              # Default sequence will be #1 - modify with if statement if sequence 2
          var seq_index = 0
          #
          #
          # Test to see if last_full_data is empty - need to create this_full_data
          if last_data == bytes('')
            last_data = [0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0]
          else
            this_full_data = this_device['last_p'] #doing this b/c the other sequence has to be retained

          end
          # Check if sequence is 2 and adjust list indexing number
          if adv_data.get(8, -1) == 2  #sequence number
            seq_index = 6
          end
          #
               # Move partial this list into full this list
          print('this_full_data_before',this_full_data)
          print('last_data_before',last_data)
          print('this_part_data_before',this_part_data)
          this_full_data[0] = this_part_data[0]
          var k=1
          while k < 7
            this_full_data[k+seq_index] = this_part_data[k]
            this_full_data[k] = last_data[k]
              print('this_full_data-'+str(k),this_full_data)
            print('last_data-'+str(k),last_data)
            k = k + 1
          end
          #                
          #     
          print('this_full_data',this_full_data)
          print('last_data',last_data)
          print('this_part_data',this_part_data)
          if this_full_data == last_data
            print('No change')
            return 0
          else
            device_config[value['mac']]['last_p'] = this_full_data
          end
          print('Made it')
          if this_device['discovery'] && !this_device['done_disc']
            publish_sensor_discovery(value['mac'], 'Battery', 'battery', '%')
            publish_sensor_discovery(value['mac'], 'Temperature_1_Status')
            publish_sensor_discovery(value['mac'], 'Temperature_1', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_1_Target', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_2_Status')
            publish_sensor_discovery(value['mac'], 'Temperature_2', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_2_Target', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_3_Status')
            publish_sensor_discovery(value['mac'], 'Temperature_3', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_3_Target', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_4_Status')
            publish_sensor_discovery(value['mac'], 'Temperature_4', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_4_Target', 'temperature', '°C')         
            device_config[value['mac']]['done_disc'] = true
            print('Discovery Complete')
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
          output_map['Battery'] = this_full_data[0]/255
          print('not before battery')
          var j=0
          while j < 4
            print(str(j))
            if this_full_data[1+(j*3)] == 6
              output_map['Temperature_'+str(j)+'_Status'] = 'Unplugged'
              output_map['Temperature_'+str(j)] = 'unavailable'
              output_map['Temperature_'+str(j)+'_Target'] = round(this_full_data[3+(j*3)]/100.0, this_device['temp_precision'])
            elif this_full_data[1+(j*3)] == 134
              output_map['Temperature_'+str(j)+'_Status'] = 'Normal'
              output_map['Temperature_'+str(j)] = round(this_full_data[2+(j*3)]/100.0, this_device['temp_precision'])
              output_map['Temperature_'+str(j)+'_Target'] = round(this_full_data[3+(j*3)]/100.0, this_device['temp_precision'])
            else
              output_map['Temperature_'+str(j)+'_Status'] = 'Alarm'
              output_map['Temperature_'+str(j)] = round(this_full_data[2+(j*3)]/100.0, this_device['temp_precision'])
              output_map['Temperature_'+str(j)+'_Target'] = round(this_full_data[3+(j*3)]/100.0, this_device['temp_precision'])
            end
            j = j + 1
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
