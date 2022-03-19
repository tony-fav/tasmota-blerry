def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length(0xFF, 0x11)
  if size(elements)
    var data = elements[0].data
    var t = data.get(10, -2)
    var t_set = data.get(12, -2)
    var t_cal = data.geti(14, -2)/100.0
    var t_on = !(t == 0xFFFF)
    var t_set_on = !(t_set == 0xFFFF)
    var t_alarm = false
    if t_on
      t = t/100.0 + t_cal
    else
      t = 'unavailable'
    end
    if t_set_on
      t_set = t_set/100.0
    else
      t_set = 'unavailable'
    end
    if t_on && t_set_on
      if t > t_set
        t_alarm = true
      end
    end
    device.add_sensor('Battery', (data[7] & 0x7F), 'battery', '%')
    device.add_binary_sensor('Probe_Status', t_on, 'connectivity')
    device.add_binary_sensor('Target_Set',  t_set_on, 'none')
    device.add_binary_sensor('Alarm',  t_alarm, 'heat')
    device.add_sensor('Temperature', t,  'temperature', '°C')
    device.add_sensor('Temperature_Target', t_set,  'temperature', '°C')
    device.add_sensor('Temperature_Calibration_C', t_cal,  'temperature', 'ΔC')
    device.add_sensor('Temperature_Calibration_F', t_cal*1.8,  'temperature', 'ΔF')
    return true
  else
    return false
  end
end
blerry_active = false
print('BLR: Driver: GVH5183 Loaded')
