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
  else
    elements = advert.get_elements_by_type_data(0x16, bytes('D2FC'), 0)
    if size(elements)
      var ad=elements[0].data[2];
      if ad!=0x40 #not an V2 unencripted
        return false
      end
      var Meas_Types = {
        0x00: {'d':'Packet_Id'},
        0x01: {'d':'Battery','u':'%'},
        0x02: {'d':'Temperature','u':'°C','d_l':-2,'f':0.01},
        0x03: {'d':'Humidity','u':'%','d_l':2,'f':0.01},
        0x04: {'d':'Pressure','u':'mBar','d_l':3,'f':0.01},
        0x05: {'d':'Light','u':'Lux','d_l':3,'f':0.01},
        0x06: {'d':'Mass','u':'Kg','d_l':2,'f':0.01},
        0x07: {'d':'Mass','u':'Pound','d_l':2,'f':0.01},
        0x08: {'d':'Dew_Point','u':'°C','d_l':-2,'f':0.01},
        0x09: {'d':'Count8'},
        0x0a: {'d':'Energy','u':'kW/h','d_l':3,'f':0.001},
        0x0b: {'d':'Power','u':'W','d_l':3,'f':0.01},
        0x0c: {'d':'Voltage','u':'V','d_l':2,'f':0.001},
        0x0d: {'d':'Pm25','u':'mg/m3','d_l':2},
        0x0e: {'d':'Pm10','u':'mg/m3','d_l':2},
        0x0f: {'d':'B_Generic'},
        0x10: {'d':'B_Power'},
        0x11: {'d':'B_Opening'},
        0x12: {'d':'Co2','u':'ppm','d_l':2},
        0x13: {'d':'Voc','u':'mg/m3','d_l':2},
        0x14: {'d':'Moisture','u':'%','d_l':2,'f':0.01},
        0x15: {'d':'B_Battery'},
        0x16: {'d':'B_Battery_Charging'},
        0x17: {'d':'B_Co'},
        0x18: {'d':'B_Cold'},
        0x19: {'d':'B_Connectivity'},
        0x1a: {'d':'B_Door'},
        0x1b: {'d':'B_Garage_Door'},
        0x1c: {'d':'B_Gas'},
        0x1d: {'d':'B_Heat'},
        0x1e: {'d':'B_Light'},
        0x1f: {'d':'B_Lock'},
        0x20: {'d':'B_Moisture'},
        0x21: {'d':'B_Motion'},
        0x22: {'d':'B_Moving'},
        0x23: {'d':'B_Occupancy'},
        0x24: {'d':'B_Plug'},
        0x25: {'d':'B_Presence'},
        0x26: {'d':'B_Problem'},
        0x27: {'d':'B_Running'},
        0x28: {'d':'B_Safety'},
        0x29: {'d':'B_Smoke'},
        0x2a: {'d':'B_Sound'},
        0x2b: {'d':'B_Tamper'},
        0x2c: {'d':'B_Vibration'},
        0x2d: {'d':'B_Window'},
        0x2e: {'d':'Humidity','u':'%'},
        0x2f: {'d':'Moisture','u':'%'},
        0x3a: {'d':'Button'},
        0x3c: {'d':'Dimmer','d_l':2},
        0x3d: {'d':'Count16','d_l':2},
        0x3e: {'d':'Count32','d_l':4},
        0x3f: {'d':'Rotation','u':'°','d_l':-2,'f':0.1},
        0x40: {'d':'Distance','u':'mm','d_l':2},
        0x41: {'d':'Distance','u':'m','d_l':2,'f':0.1},
        0x42: {'d':'Duration','u':'s','d_l':3,'f':0.001},
        0x43: {'d':'Current','u':'A','d_l':2,'f':0.001},
        0x44: {'d':'Speed','u':'m/s','d_l':2,'f':0.01},
        0x45: {'d':'Temperature','u':'°C','d_l':-2,'f':0.1},
        0x46: {'d':'Uv_Index','d_l':1,'f':0.1},
        0x47: {'d':'Volume','u':'L','d_l':2,'f':0.1},
        0x48: {'d':'Volume','u':'mL','d_l':2},
        0x49: {'d':'Volume_Flow_Rate','u':'m3/h','d_l':2,'f':0.001},
        0x4a: {'d':'Voltage','u':'V','d_l':2,'f':0.1}
      }
      var dp_val = nil
      var data = elements[0].data[3..]
      var i = 0
      var protec = 0
      while i < size(data)
        var mt = data[i]
        var dp_len = 1
        if Meas_Types[mt].contains('d_l')
          dp_len = Meas_Types[mt]['d_l']
        end
        var dp_dtype = Meas_Types[mt]['d']
        var d_fact = 1
        if Meas_Types[mt].contains('f')
          d_fact = Meas_Types[mt]['f']
        end
        var d_unit = ''
        if Meas_Types[mt].contains('u')
          d_unit = Meas_Types[mt]['u']
        end
        var dp_rval = data[i+1..i+1+dp_len]
        
        if dp_len > 0
          dp_val = dp_rval.get(0, dp_len)
        else
          dp_len = -dp_len
          dp_val = dp_rval.geti(0, dp_len)
        end

        if dp_dtype[0..1]=='B_'
          device.add_binary_sensor(dp_dtype[2..], dp_val,  'battery')
        elif mt == 0x00
          device.add_attribute(dp_dtype, dp_val)
        else
          print(dp_dtype, d_fact, dp_val, d_unit)
          device.add_sensor(dp_dtype, d_fact*dp_val,  dp_dtype, d_unit)
        end

        i = i + dp_len + 1
      end
    end
  end
  return true
end
blerry_active = false
print('BLY: Driver: BTHome Loaded')
