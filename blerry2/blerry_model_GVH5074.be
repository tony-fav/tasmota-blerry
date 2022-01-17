def blerry_handle(device, advert)
  var elements_GVH5074 = advert.get_elements_by_type_length_data(0xFF, 0x0A, bytes('88EC'), 0)

  if size(elements_GVH5074)
    var data = elements_GVH5074[0].data
    var t = blerry_helpers.twos_complement(data.get(3,2), 16)/100.0
    var h = data.get(5,2)/100.0
    var dewp = blerry_helpers.get_dewpoint(t, h)
    device.add_sensor('Temperature', t,  'temperature', '°C')
    device.add_sensor('Humidity', h, 'humidity', '%')
    device.add_sensor('DewPoint', dewp, 'temperature', '°C')
    device.add_sensor('Battery', data.get(7,1), 'battery', '%')
    return true
    
  else
    return false
  end
end
blerry_active = true
