def blerry_handle(device, advert)
  var elements_ATC = advert.get_elements_by_type_length_data(0x16, 16, bytes('1A18'), 0)
  var elements_PVVX = advert.get_elements_by_type_length_data(0x16, 18, bytes('1A18'), 0)

  if size(elements_PVVX)
    var data = elements_PVVX[0].data
    var t = data.geti(8,2)/100.0
    var h = data.get(10,2)/100.0
    var dewp = blerry_helpers.get_dewpoint(t, h)
    device.add_sensor('Temperature', t,  'temperature', '°C')
    device.add_sensor('Humidity', h, 'humidity', '%')
    device.add_sensor('DewPoint', dewp, 'temperature', '°C')
    device.add_sensor('Battery_Voltage', data.get(12,2)/1000.0, 'voltage', 'V')
    device.add_sensor('Battery', data.get(14,1), 'battery', '%')
    device.add_attribute('Count', data.get(15,1))
    var flag = data.get(16,1)
    device.add_attribute('Flag', flag)
    device.add_binary_sensor('GPIO_PA6', blerry_helpers.bitval(flag, 0), 'none')
    device.add_binary_sensor('GPIO_PA5', blerry_helpers.bitval(flag, 1), 'none')
    device.add_binary_sensor('Triggered_by_Temperature', blerry_helpers.bitval(flag, 2), 'none')
    device.add_binary_sensor('Triggered_by_Humidity', blerry_helpers.bitval(flag, 3), 'none')
    return true

  elif size(elements_ATC)
    var data = elements_ATC[0].data
    var t = data.geti(8,-2)/10.0
    var h = data.get(10,1)
    var dewp = blerry_helpers.get_dewpoint(t, h)
    device.add_sensor('Temperature', t,  'temperature', '°C')
    device.add_sensor('Humidity', h, 'humidity', '%')
    device.add_sensor('DewPoint', dewp, 'temperature', '°C')
    device.add_sensor('Battery', data.get(11,1), 'battery', '%')
    device.add_sensor('Battery_Voltage', data.get(12,-2)/1000.0, 'voltage', 'V')
    return true
    
  else
    return false
  end
end
blerry_active = false
print('BLY: Driver: ATCpvvx Loaded')
