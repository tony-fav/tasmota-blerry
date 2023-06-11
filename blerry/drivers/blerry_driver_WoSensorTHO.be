# SwitchBot Indoor/Outdoor Thermo-Hygrometer
# https://us.switch-bot.com/products/switchbot-indoor-outdoor-thermo-hygrometer
# Model: W3400010
# https://github.com/OpenWonderLabs/SwitchBotAPI-BLE/issues/26#issuecomment-1585525955
def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length(0xFF, 0x0F)
  if size(elements)
    var data = elements[0].data
    # Assumption that the leading 69 is significant.
    if data[0] != 0x69
        return false
    end
    device.add_attribute('DevID', 'WoSensorTHO')
    var t = ((data[10] & 0x0F) * 0.1 + (data[11] & 0x7F))
    if (data[11]&0x80) == 0
      t = -1 * t
    end
    var h = data[12] & 0x7F
    var dewp = blerry_helpers.get_dewpoint(t, h)
    device.add_sensor('Temperature', t,  'temperature', '°C')
    device.add_sensor('Humidity', h, 'humidity', '%')
    device.add_sensor('DewPoint', dewp, 'temperature', '°C')
  end
  elements = advert.get_elements_by_type_length(0x16, 0x06)
  if size(elements)
    var data = elements[0].data
    device.add_sensor('Battery', data[4] & 0x7F, 'battery', '%')
  end
  return true
end
blerry_active = true
print('BLY: Driver: WoSensorTHO Loaded')
