def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length(0xFF, 0x07)
  if size(elements)
    var data = elements[0].data
    var t = data.geti(1,2)/10.0
    var h = data.get(3,2)/10.0
    var dewp = blerry_helpers.get_dewpoint(t, h)
    device.add_sensor('Temperature', t,  'temperature', '°C')
    device.add_sensor('Humidity', h, 'humidity', '%')
    device.add_sensor('DewPoint', dewp, 'temperature', '°C')
    return true
  else
    return false
  end
end
blerry_active = true
print('BLR: Driver: ThermoPro_TP59 Loaded')
