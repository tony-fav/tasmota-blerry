# Switchbot Contact Sensor
# https://github.com/OpenWonderLabs/python-host/wiki/Contact-Sensor-BLE-open-API
# Tested on Contact Sensor firmware v1.1
def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length_data(0x16, 0x0C, bytes('3DFD'), 0)
  if size(elements)
    var data = elements[0].data
    # print('----------------------------------------')
    # print('PIR    :', (data[ 3] & 0x40) >> 6) # 0 = no motion, 1 = motion
    # print('Battery:', (data[ 4] & 0x7F) >> 0) # percentage
    # print('HAL    :', (data[ 5] & 0x06) >> 1) # 0 = closed, 1 = open, 2 = open longer than timout (in app choosable)
    # print('LUX    :', (data[ 5] & 0x01) >> 0) # 0 = dark, 1 = bright (in app calibratable)
    # print('Button :', (data[10] & 0x0F) >> 0) # 1 through 15 with rollover.
    # print('----------------------------------------')
    device.add_binary_sensor('Motion', blerry_helpers.bitval(data[3], 6), 'motion')
    device.add_sensor('Battery', data[4] & 0x7F, 'battery', '%')
    device.add_binary_sensor('Contact', (data[5] & 0x06) >> 1, 'opening')
    device.add_binary_sensor('Lux', data[5] & 0x01, 'light')
    var btn_pre = device.get_attribute('Button_Count')
    var btn = data[10] & 0x0F
    device.add_attribute('Button_Count', btn)
    if btn_pre != nil
      if btn_pre.value != btn
        device.add_binary_sensor('Button', true, 'none')
        device.publish() # force publish
        device.add_binary_sensor('Button', false, 'none')
        device.publish() # force publish
      end
    end
    return true
  else
    return false
  end
end
blerry_active = true
print('BLY: Driver: WoContact Loaded')
