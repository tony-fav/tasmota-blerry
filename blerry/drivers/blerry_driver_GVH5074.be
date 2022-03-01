def blerry_handle(device, advert)
  var elements_GVH5074 = advert.get_elements_by_type_length_data(0xFF, 0x0A, bytes('88EC'), 0)
  var elements_GVH5179 = advert.get_elements_by_type_length_data(0xFF, 0x0C, bytes('0188'), 0)
  var data
  var s

  if size(elements_GVH5074)
    data = elements_GVH5074[0].data
    s = 3
  elif size(elements_GVH5179)
    data = elements_GVH5179[0].data
    s = 6
  else
    return false
  end
  
  var t = data.geti(s+0, 2)/100.0
  var h = data.get(s+2, 2)/100.0
  var dewp = blerry_helpers.get_dewpoint(t, h)
  device.add_sensor('Temperature', t,  'temperature', '°C')
  device.add_sensor('Humidity', h, 'humidity', '%')
  device.add_sensor('DewPoint', dewp, 'temperature', '°C')
  device.add_sensor('Battery', data.get(s+4, 1), 'battery', '%')
  return true
end
blerry_active = true
print('BLY: Driver: GVH5074 Loaded')
