def blerry_handle(device, advert)
  var elements_IBSTH2 = advert.get_elements_by_type_length(0xFF, 0x0A)
  if size(elements_IBSTH2)
    var data = elements_IBSTH2[0].data
    var has_humidity = (data.get(2,2) != 0)
    var t = data.geti(0,2)/100.0
    device.add_sensor('Temperature', t,  'temperature', '°C')
    if has_humidity
      var h = data.get(2,2)/100.0
      var dewp = blerry_helpers.get_dewpoint(t, h)
      device.add_sensor('Humidity', h, 'humidity', '%')
      device.add_sensor('DewPoint', dewp, 'temperature', '°C')
    end
    device.add_sensor('Battery', data.get(7,1), 'battery', '%')
    return true
  else
    return false
  end
end
blerry_active = true
