def blerry_handle(device, advert)
  var elements_GVH5075 = advert.get_elements_by_type_length_data(0xFF, 0x09, bytes('88EC'), 0) # H5075 and H5072
  var elements_GVH5101 = advert.get_elements_by_type_length_data(0xFF, 0x09, bytes('0100'), 0) # H5101 and H5102

  var data
  if size(elements_GVH5075)
    data = elements_GVH5075[0].data[3..]
  elif size(elements_GVH5101)
    data = elements_GVH5101[0].data[4..]
  else
    return false
  end

  var basenum = (bytes('00') + data[0..2]).get(0, -4)
  var t
  if basenum & 0x800000
    t = (basenum & 0x7FFFFF)/-10000.0
  else
    t = basenum/10000.0
  end
  var h = ((basenum & 0x7FFFFF) % 1000)/10.0
  var dewp = blerry_helpers.get_dewpoint(t, h)
  device.add_sensor('Temperature', t,  'temperature', '°C')
  device.add_sensor('Humidity', h, 'humidity', '%')
  device.add_sensor('DewPoint', dewp, 'temperature', '°C')
  device.add_sensor('Battery', data.get(3,1), 'battery', '%')
  return true
end
blerry_active = false
