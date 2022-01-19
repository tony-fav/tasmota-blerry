# Switchbot Motion Sensor
# https://github.com/OpenWonderLabs/python-host/wiki/Motion-Sensor-BLE-open-API
# Tested on Motion Sensor firmware v1.3
def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length_data(0x16, 0x09, bytes('3DFD'), 0)
  if size(elements)
    var data = elements[0].data
    device.add_binary_sensor('Motion', blerry_helpers.bitval(data[3], 6), 'motion')
    device.add_binary_sensor('Lux', (data[7] & 0x03) == 2, 'light')
    device.add_sensor('Battery', data[4] & 0x7F, 'battery', '%')
    return true
  else
    return false
  end
end
blerry_active = true
print('BLY: Driver: WoPresence Loaded')
