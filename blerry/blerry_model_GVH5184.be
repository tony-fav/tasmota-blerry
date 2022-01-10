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
        # Build this_part_data with probe-a state, probe-a temp, probe-a set, probe-b state, probe-b temp, probe-b set
        var this_part_data = [adv_data.get(9, -1), adv_data.get(10, -2), adv_data.get(12, -2), adv_data.get(14, -1), adv_data.get(15, -2), adv_data.get(17, -2)]
        var last_full_data = this_device['last_p']
        var this_full_data = [ 0, [-1, 0, 0, 0, 0, 0], [-1, 0, 0, 0, 0, 0], 0 ]
        var seq_num = adv_data.get(8, -1)
        print('We have a packet.')
        # If first time thru - create data structure.
        # last_full_data[ Battery, [Probe1&2 Data], [Probe3&4 Data], UpdateDelayCounter ] 
        if last_full_data == bytes('')
          last_full_data  = [ -1, [-1, 0, 0, 0, 0, 0], [-1, 0, 0, 0, 0, 0], 0 ]
        else
          this_full_data = last_full_data
        end
        #Check if new data is the same as old data and return - unless we haven't updated in 30 cycles      
        print('Sequence Number',seq_num)
        print('Cycle Count',last_full_data[3])
        if (this_part_data == last_full_data[seq_num]) && (last_full_data[3] < 31)
          print('bye - data packets are the same and cycle count is less than 31')
          print(this_full_data)
          print('')
          this_full_data[3]=this_full_data[3]+1
          device_config[value['mac']]['last_p'] = this_full_data.copy()
          return 0
        end
        # Update battery with current value even if no change
        this_full_data[0]= adv_data.get(7, -1)
        print('Battery Value',this_full_data[0])
        # Increment cycle counter
#        if this_full_data[3] > 30
          this_full_data[3] = 0
#        else
#          this_full_data[3]=this_full_data[3]+1
#        end
        # Update bank 1 or 2
        print('Before',this_full_data[seq_num])
        this_full_data[seq_num]=this_part_data.copy()
        print('Before',this_full_data[seq_num])
        device_config[value['mac']]['last_p'] = this_full_data.copy()
        # If we still have a bank with a negative 1 - then wait until both banks populated
        if (this_full_data[1][0] < 0) || (this_full_data[2][0]) < 0
          print('bye - still have negative values')
          print(this_full_data)
          print('')
          return 0
        end
        # Do device discovery after we have all of the values but only once
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
          print('Yay - Device Discovery happened.')
        end   
        # Create map of all the values needed for the MQTT JSON packet
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
        # Outer Loop - which bank? Bank 1 is probe 1 & 2, Bank 2 is probe 3 & 4
        for j:1 .. 2
          # Inner loop - which probe - note (k-j)==-1 is Probe[a] and (k-j)==0 is Probe[b]
          for k:j-1 .. j
            var probeset
            # Determin what probe states/temps and create list for publishing
            if this_full_data[j][3+((k-j)*3)] == 198 # This is the alarm branch
              probeset = ['ON', 'ON']              
            elif this_full_data[j][3+((k-j)*3)] == 134 # This is the normal branch
              probeset = ['ON', 'OFF']              
            else                                      # This is the unplugged branch.
              probeset = ['OFF', 'OFF']
            end
            # Add the current temp to the list - position 1 or 4
            if this_full_data[j][4+((k-j)*3)]==65535
              probeset = probeset .. 'unavailable'
            else
              probeset = probeset .. round(this_full_data[j][4+((k-j)*3)]/100.0, this_device['temp_precision'])
            end           
            # Add the setpoint to the list - position 2 or 5
            if this_full_data[j][5+((k-j)*3)]==65535
              probeset = probeset .. 'unavailable'
            else
              probeset = probeset .. round(this_full_data[j][5+((k-j)*3)]/100.0, this_device['temp_precision'])
            end
            print(probeset)
            output_map['Temperature_'+str(j+k)+'_Status'] = probeset[0]
            output_map['Temperature_'+str(j+k)+'_Alarm'] = probeset[1]
            output_map['Temperature_'+str(j+k)] = probeset[2]
            output_map['Temperature_'+str(j+k)+'_Target'] = probeset[3]
          end
        end
        # Publish data
        var this_topic = base_topic + '/' + this_device['alias']
        tasmota.publish(this_topic, json.dump(output_map), this_device['sensor_retain'])
        if this_device['publish_attributes']
          for output_key:output_map.keys()
            tasmota.publish(this_topic + '/' + output_key, string.format('%s', output_map[output_key]), this_device['sensor_retain'])
          end     
        end
        print('We made it to the end of publish.')
        print('')
        print('')
      end          
      i = i + adv_len + 1
    end
  end
end

# map function into handles array
device_handles['GVH5184'] = handle_GVH5184
require_active['GVH5184'] = false
