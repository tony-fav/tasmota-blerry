# Switchbot Bot
# https://github.com/OpenWonderLabs/python-host/wiki/Motion-Sensor-BLE-open-API
# Tested on Bot firmware v4.9
def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length_data(0x16, 0x06, bytes('000D'), 0)
  if size(elements)
    var data = elements[0].data
    device.add_binary_sensor('Switch_Mode', blerry_helpers.bitval(data[3], 7), 'none')
    device.add_binary_sensor('Button_Mode', 1-blerry_helpers.bitval(data[3], 7), 'none')
    var switch_state = 'unavailable'
    if blerry_helpers.bitval(data[3], 7)
      switch_state = 1-blerry_helpers.bitval(data[3], 6)
    end
    device.add_binary_sensor('Switch_State', switch_state, 'none')
    device.add_sensor('Battery', data[4] & 0x7F, 'battery', '%')
    var base = 'BLEOp1 m:%s s:cba20d00-224d-11e6-9fb8-0002a5d5c51b c:cba20002-224d-11e6-9fb8-0002a5d5c51b w:57%s n:cba20003-224d-11e6-9fb8-0002a5d5c51b go'
    device.add_action('Mode_Button', string.format(base, device.mac, '036400'))
    device.add_action('Mode_Button_Inv', string.format(base, device.mac, '036401'))
    device.add_action('Mode_Switch', string.format(base, device.mac, '036410'))
    device.add_action('Mode_Switch_Inv', string.format(base, device.mac, '036411'))
    device.add_action('Press', string.format(base, device.mac, '01'))
    device.add_action('Switch_On', string.format(base, device.mac, '0101'))
    device.add_action('Switch_Off', string.format(base, device.mac, '0102'))
    device.add_action('Switch_Hold', string.format(base, device.mac, '0103'))
    device.add_action('Switch_Close', string.format(base, device.mac, '0104'))
    return true
  else
    return false
  end
end
blerry_active = true
print('BLY: Driver: WoHand Loaded')
