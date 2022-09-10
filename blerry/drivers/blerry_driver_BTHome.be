# https://bthome.io/
def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_data(0x16, bytes('1C18'), 0)
  if size(elements)
    var data = elements[0].data[2..]
    var i = 0
    var protec = 0
    while i < size(data)
      var fb = data[i]
      var dp_len = fb & 0x1F
      var dp_dtype = (fb & 0xE0) >> 5
      var dp_mtype = data[i+1]
      var dp_rval = data[i+2..i+dp_len]
      var debug_print = false
      var dp_val = nil
      
      if dp_dtype == 0
        dp_val = dp_rval.get(0, dp_len-1)
      elif dp_dtype == 1
        dp_val = dp_rval.geti(0, dp_len-1)
      else 
        debug_print = true
      end

      if dp_val
        if dp_mtype == 0x00
          device.add_attribute('PacketID', dp_val)
        elif dp_mtype == 0x01
          device.add_sensor('Battery', dp_val,  'battery', '%')
        elif dp_mtype == 0x02
          device.add_sensor('Temperature', 0.01*dp_val,  'temperature', '°C')
        elif dp_mtype == 0x03
          device.add_sensor('Humidity', 0.01*dp_val,  'humidity', '%')
        elif dp_mtype == 0x0C
          device.add_sensor('Battery_Voltage', 0.001*dp_val, 'voltage', 'V')
        else
          debug_print = true
        end
      end

      if debug_print
        print('BTHome Debug Data')
        print('len: ' + str(dp_len))
        print('dtype: ' + str(dp_dtype))
        print('mtype: ' + str(dp_mtype))
        print('rval: ' + str(dp_rval))
        print('val ' + str(dp_val))
      end

      i = i + dp_len + 1
      protec = protec + 1
      if protec > 10
        return false
      end
    end
  end
  return true
end
blerry_active = false
print('BLY: Driver: BTHome Loaded')
