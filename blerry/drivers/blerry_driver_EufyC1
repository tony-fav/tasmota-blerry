def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length(0xFF, 0x15)
  if size(elements)
    var data = elements[0].data[7..10]
    if (data[0] == 0 && data[1] == 0)
      return false
    end
    var weight = data.get(2, 2)/100
    device.add_sensor_in_range('Weight', weight, nil, 'kg', 0.0, nil)
    var impedance = data.get(0, 2)/10
    device.add_sensor_in_range('Impedance', impedance, nil, 'ohm', 0., 3000.)
  end
  return true
end
blerry_active = false
print('BLY: Driver:  EufyC1 Loaded')
