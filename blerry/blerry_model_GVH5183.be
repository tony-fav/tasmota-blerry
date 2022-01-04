def handle_GVH5183(value, trigger, msg)
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
      if (adv_type == 0xFF) && (adv_len == 0x11)
          var this_data = [adv_data.get(10, -2), adv_data.get(12, -2), adv_data.geti(14, -2)]
          var last_data = this_device['last_p']
          if (last_data != bytes('')) && (this_data == last_data)
            return 0
          end
          device_config[value['mac']]['last_p'] = this_data
          if this_device['discovery'] && !this_device['done_disc']
            publish_sensor_discovery(value['mac'], 'Temperature', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_Target', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_Calibration_C', 'temperature', 'ΔC')
            publish_sensor_discovery(value['mac'], 'Temperature_Calibration_F', 'temperature', 'ΔF')
            publish_binary_sensor_discovery(value['mac'], 'Probe_Status', 'connectivity')
            publish_binary_sensor_discovery(value['mac'], 'Target_Set', 'none')
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
          if this_data[0] == 65535
            output_map['Probe_Status'] = 'OFF'
            output_map['Temperature'] = "unavailable"
          else
            output_map['Probe_Status'] = 'ON'
            output_map['Temperature'] = round((this_data[0] + this_data[2])/100.0, this_device['temp_precision'])
          end
          if this_data[1] == 65535
            output_map['Target_Set'] = 'OFF'
            output_map['Temperature_Target'] = "unavailable"
          else
            output_map['Target_Set'] = 'ON'
            output_map['Temperature_Target'] = round(this_data[1]/100.0, this_device['temp_precision'])
          end
          output_map['Temperature_Calibration_C'] = round(this_data[2]/100.0, this_device['temp_precision'])
          output_map['Temperature_Calibration_F'] = round(this_data[2]/100.0*1.8, this_device['temp_precision'])
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
device_handles['GVH5183'] = handle_GVH5183
require_active['GVH5183'] = false

# command functions
def xor8(x)
  var n = size(x)
  var y = x[0]
  for i:1..n-1
    y = y ^ x[i]
  end
  return y
end

def xor8append(x)
  var y = x.copy()
  y.add(xor8(x), 1)
  return y
end

def GVH5183_Write(mac, payload)
  var base = 'BLEOp1 m:%s s:494e5445-4c4c-495f-524f-434b535f4857 c:494e5445-4c4c-495f-524f-434b535f2011 w:%s go'
  tasmota.cmd(string.format(base, mac, payload))
end

def GVH5183_SetTemperatureTargetC(mac, temp)
  var msg = string.format('3309%02x%02x0600b9000000000000000000000000', int(100*temp) >> 8, int(100*temp) & 0xFF)
  #                        ---- command 33, to set target 09
  #                            -------- big endian temp
  #                                    -- "diy" temp
  #                                      ---- no idea. identifier so app can associate with a name maybe?
  msg = xor8append(bytes(msg)).tostring()[7..-3]
  GVH5183_Write(mac, msg)
end

def GVH5183_SetTemperatureTargetF(mac, temp)
  GVH5183_SetTemperatureTargetC(mac, (temp - 32)/1.8)
end

def GVH5183_ClearTemperatureTarget(mac)
  GVH5183_Write(mac, '3309ffffffffff000000000000000000000000c5')
end

def GVH5183_EnableAlarm(mac) # App calls it buzzer, has no effect on the passive BLE packet
  GVH5183_Write(mac, '3307010000000000000000000000000000000035')
end

def GVH5183_DisableAlarm(mac) # App calls it buzzer, has no effect on the passive BLE packet
  GVH5183_Write(mac, '3307000000000000000000000000000000000034')
end

def GVH5183_SetTemperatureCalibrationC(mac, temp) # app has min -5, max 5
  var msg = string.format('3308%02x%02x000000000000000000000000000000', (int(100*temp) >> 8) & 0xFF, int(100*temp) & 0xFF)
  msg = xor8append(bytes(msg)).tostring()[7..-3]
  GVH5183_Write(mac, msg)
end

def GVH5183_SetTemperatureCalibrationF(mac, temp) # app has min -9, max 9
  GVH5183_SetTemperatureCalibrationC(mac, temp/1.8)
end