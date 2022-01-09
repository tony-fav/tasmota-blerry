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
          var last_full_data = this_device['last_p']
          var last_part_data = [-1, -1, 0, 0, 0, 0, 0]
          var this_full_data = this_device['last_p']
          var seq_index = 0 # Default sequence will be #1 - modify with if statement if sequence 2
          var j = 1 # Default counter start
          #
          #
          # Test to see if last_full_data is empty - need to create this_full_data & last_full_data
          if last_full_data == bytes('')
            last_full_data = [0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0]
            this_full_data  = [0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0]
          end
          # Check if sequence is 2 and adjust list indexing number
          if adv_data.get(8, -1) == 2  #sequence number
            seq_index = 6
          end
          print('last_part_data',last_part_data)
          print('this_part_data',this_part_data)
          print('')
          print('this_full_data_before',this_full_data)
          print('last_data_before',last_full_data)
          # Move battery value into last_part_data
          last_part_data[0]=this_part_data[0]
          print('last_part_data',last_part_data)
          print('this_part_data',this_part_data)
          print('')
          print('this_full_data_before',this_full_data)
          print('last_data_before',last_full_data)
          # Move battery value into last_part_data
          # Fill last_part_data with probe values from last_full_data for testing later
          while j < 7
            last_part_data[j] = last_full_data[j+seq_index]
            j = j + 1
          end
          
          # Set loop counter at first probe value - skip battery
          j=1
          #set battery value
          this_full_data[0] = this_part_data[0]
          while j < 7
            this_full_data[j+seq_index] = this_part_data[j]
            this_full_data[j] = last_full_data[j]
            print('')
            print('       this_full_data-'+str(j),this_full_data)
            print('       last_data-'+str(j),last_full_data)
            j = j + 1
          end
          #                
          #     
          print('')
          print('this_full_data',this_full_data)
          print('last_data',last_full_data)
          print('this_part_data',this_part_data)
          print('last_part_data',last_part_data)
          if this_part_data == last_part_data
            print('No change')
            return 0
          else
            device_config[value['mac']]['last_p'] = this_full_data
          end
          print('Made it')
          if this_full_data[1] < 0 || this_full_data[8] < 0
            print('Negative Values')
            return 0
          end
          if this_device['discovery'] && !this_device['done_disc']
            publish_sensor_discovery(value['mac'], 'Battery', 'battery', '%')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_1_Status', 'plug')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_1_Alarm', 'heat')
            publish_sensor_discovery(value['mac'], 'Temperature_1', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_1_Target', 'temperature', '°C')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_2_Status', 'plug')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_2_Alarm', 'heat')
            publish_sensor_discovery(value['mac'], 'Temperature_2', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_2_Target', 'temperature', '°C')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_3_Status', 'plug')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_3_Alarm', 'heat')
            publish_sensor_discovery(value['mac'], 'Temperature_3', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_3_Target', 'temperature', '°C')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_4_Status', 'plug')
            publish_binary_sensor_discovery(value['mac'], 'Temperature_4_Alarm', 'heat')
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
          output_map['Battery'] = math.ceil(this_full_data[0]/255.0*100.0)
          print(math.ceil(this_full_data[0]/255.0*100.0))
          print('not before battery')
          j=0
          while j < 4
            print(str(j))
            if this_full_data[1+(j*3)] == 198
              print('Alarm Branch')
              output_map['Temperature_'+str(j+1)+'_Status'] = 'on'
              output_map['Temperature_'+str(j+1)+'_Alarm'] = 'on'
              output_map['Temperature_'+str(j+1)] = round(this_full_data[2+(j*3)]/100.0, this_device['temp_precision'])
              if this_full_data[3+(j*3)]==65535
                output_map['Temperature_'+str(j+1)+'_Target'] = 'unavailable'

              else
                output_map['Temperature_'+str(j+1)+'_Target'] = round(this_full_data[3+(j*3)]/100.0, this_device['temp_precision'])
              end
            elif this_full_data[1+(j*3)] == 134
              print('Normal Branch')
              output_map['Temperature_'+str(j+1)+'_Status'] = 'on'
              output_map['Temperature_'+str(j+1)+'_Alarm'] = 'off'
              output_map['Temperature_'+str(j+1)] = round(this_full_data[2+(j*3)]/100.0, this_device['temp_precision'])
              if this_full_data[3+(j*3)]==65535
                output_map['Temperature_'+str(j+1)+'_Target'] = 'unavailable'

              else
                output_map['Temperature_'+str(j+1)+'_Target'] = round(this_full_data[3+(j*3)]/100.0, this_device['temp_precision'])
              end
            else
              print('Unplugged Branch')
              output_map['Temperature_'+str(j+1)+'_Status'] = 'off'
              output_map['Temperature_'+str(j+1)+'_Alarm'] = 'off'
              output_map['Temperature_'+str(j+1)] = 'unavailable'
              if this_full_data[3+(j*3)]==65535
                output_map['Temperature_'+str(j+1)+'_Target'] = 'unavailable'

              else
                output_map['Temperature_'+str(j+1)+'_Target'] = round(this_full_data[3+(j*3)]/100.0, this_device['temp_precision'])
              end
            end
            j = j + 1
            print('map pass'+str(j))
          end      
          var this_topic = base_topic + '/' + this_device['alias']
          print(json.dump(output_map))
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
