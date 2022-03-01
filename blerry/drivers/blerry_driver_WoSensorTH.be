# Switchbot Temp and Humidity Sensor
# https://github.com/OpenWonderLabs/python-host/wiki/Meter-BLE-open-API#new-broadcast-message
def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length_data(0x16, 0x09, bytes('000D'), 0)
  if size(elements)
    var data = elements[0].data
    var t = (data[6] & 0x7F) + (data[5] & 0x0F)/10.0
    if (data[6] & 0x80) == 0
      t = -1*t
    end
    var h = data[7] & 0x7F
    var dewp = blerry_helpers.get_dewpoint(t, h)
    device.add_sensor('Temperature', t,  'temperature', '°C')
    device.add_sensor('Humidity', h, 'humidity', '%')
    device.add_sensor('DewPoint', dewp, 'temperature', '°C')
    device.add_sensor('Battery', data[4] & 0x7F, 'battery', '%')
    return true
  else
    return false
  end
end
blerry_active = true
print('BLY: Driver: WoSensorTH Loaded')
