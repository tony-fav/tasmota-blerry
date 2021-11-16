var fake_print_time = tasmota.millis(5000)
fake_ble = Driver()
fake_ble.every_second = def ()
  if tasmota.millis() > fake_print_time
    tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"A4C138AAAAAA\",\"a\":\"govee5075\",\"RSSI\":-76,\"p\":\"0D09475648353037355F32443830030388EC02010509FF88EC0082F8B05800\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"494207BBBBBB\",\"a\":\"inkbirdth\",\"RSSI\":-83,\"p\":\"0201060302F0FF\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"D4E4A3CCCCCC\",\"a\":\"sbot_temp\",\"RSSI\":-75,\"p\":\"02010609FF5900D4E4A3CCCCCC\"}','test'}
    fake_print_time = tasmota.millis(5000)
  end
end
tasmota.add_driver(fake_ble)