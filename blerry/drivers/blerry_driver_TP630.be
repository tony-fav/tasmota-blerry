def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length(0xff, 19)

  if size(elements)
    var data = elements[0].data
    # got decoding from here: https://github.com/ra6070/BLE-TPMS
    device.add_sensor('Pressure', data.get(8,4)/100000.0, 'pressure', 'bar')
    device.add_sensor('Temperature', data.get(12,4)/100.0,  'temperature', '°C')
    device.add_sensor('Battery', data.get(16,1), 'battery', '%')
    device.add_sensor('Alarm', data.get(17,1), 'alarm', '')
    return true
  else
    return false
  end

end
blerry_active = false
print('BLY: Driver: TP630 Loaded')
