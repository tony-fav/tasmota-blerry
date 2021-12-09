var fake_print_time = tasmota.millis(5000)
fake_ble = Driver()
fake_ble.every_second = def ()
  if tasmota.millis() > fake_print_time
    tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"A4C138AAAAAA\",\"a\":\"govee5075_passive\",\"RSSI\":-76,\"p\":\"0D09475648353037355F32443830030388EC02010509FF88EC0082F8B05800\"}}','test')
    tasmota.publish.result('{\"DetailsBLE\":{\"mac\":\"A4C138BBBBBB\",\"a\":\"govee5075_active\",\"RSSI\":-83,\"p\":\"0D09475648353037355F32443830030388EC02010509FF88EC0081EBD355001AFF4C000215494E54454C4C495F524F434B535F48575075F2FFC2\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"494207AAAAAA\",\"a\":\"inkbirdth_passive\",\"RSSI\":-83,\"p\":\"0201060302F0FF\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"494207BBBBBB\",\"a\":\"inkbirdth_active\",\"RSSI\":-83,\"p\":\"0201060302F0FF04097370730AFF3E09F11000526A6408\"}}','test')
    tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"494207CCCCCC\",\"a\":\"inkbirdth_active_noH\",\"RSSI\":-83,\"p\":\"0201060302F0FF04097470730AFF5CFA000000C4D54908\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"D4E4A3AAAAAA\",\"a\":\"sbot_temp\",\"RSSI\":-75,\"p\":\"02010609FF5900D4E4A3AAAAAA\"}','test'}
    fake_print_time = tasmota.millis(5000)
  end
end
tasmota.add_driver(fake_ble)