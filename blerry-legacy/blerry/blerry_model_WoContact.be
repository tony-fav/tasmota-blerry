# Switchbot Contact Sensor
# https://github.com/OpenWonderLabs/python-host/wiki/Contact-Sensor-BLE-open-API
# Tested on Contact Sensor firmware v1.1
def handle_WoContact(value, trigger, msg)
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
      if (adv_type == 0x16) && (adv_len == 0x0C) && (adv_data[0..1] == bytes('3DFD'))
        # print('----------------------------------------')
        # print('PIR    :', (adv_data[ 3] & 0x40) >> 6) # 0 = no motion, 1 = motion
        # print('Battery:', (adv_data[ 4] & 0x7F) >> 0) # percentage
        # print('HAL    :', (adv_data[ 5] & 0x06) >> 1) # 0 = closed, 1 = open, 2 = open longer than timout (in app choosable)
        # print('LUX    :', (adv_data[ 5] & 0x01) >> 0) # 0 = dark, 1 = bright (in app calibratable)
        # print('Button :', (adv_data[10] & 0x0F) >> 0) # 1 through 15 with rollover.
        # print('----------------------------------------')
        # Because there is so much extra info in the data that does change, we do last_data differently than normal.
        var this_data = [(adv_data[ 3] & 0x40) >> 6, adv_data[ 4] & 0x7F, (adv_data[ 5] & 0x06) >> 1, adv_data[ 5] & 0x01, adv_data[10] & 0x0F] # PIR, Bat, HAL, Lux, Btn
        var last_data = this_device['last_p']
        if last_data == bytes('')
          device_config[value['mac']]['last_p'] = this_data
          return 0
        end
        if this_data == last_data
          return 0
        else
          device_config[value['mac']]['last_p'] = this_data
        end
        if this_device['discovery'] && !this_device['done_disc']
          publish_binary_sensor_discovery(value['mac'], 'Motion', 'motion')
          publish_sensor_discovery(value['mac'], 'Battery', 'battery', '%')
          publish_binary_sensor_discovery(value['mac'], 'Contact', 'opening')
          publish_binary_sensor_discovery(value['mac'], 'Lux', 'light')
          publish_binary_sensor_discovery(value['mac'], 'Button', 'none')
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
        if this_data[0] > 0
          output_map['Motion'] = 'ON'
        else
          output_map['Motion'] = 'OFF'
        end
        output_map['Battery'] = this_data[1]
        if this_data[2] > 0
          output_map['Contact'] = 'ON'
        else
          output_map['Contact'] = 'OFF'
        end
        if this_data[3] > 0
          output_map['Lux'] = 'ON'
        else
          output_map['Lux'] = 'OFF'
        end
        if this_data[4] != last_data[4]
          output_map['Button'] = 'ON'
        else
          output_map['Button'] = 'OFF'
        end
        var this_topic = base_topic + '/' + this_device['alias']
        tasmota.publish(this_topic, json.dump(output_map), this_device['sensor_retain'])
        if this_device['publish_attributes']
          for output_key:output_map.keys()
            tasmota.publish(this_topic + '/' + output_key, string.format('%s', output_map[output_key]), this_device['sensor_retain'])
          end
        end
        # clear button 
        if output_map['Button'] == 'ON'
          output_map['Button'] = 'OFF'
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
device_handles['WoContact'] = handle_WoContact
require_active['WoContact'] = true