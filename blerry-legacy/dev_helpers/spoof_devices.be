var fake_print_time = tasmota.millis(5000)
fake_ble = Driver()
fake_ble.every_second = def ()
  if tasmota.millis() > fake_print_time
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"A4C138AAAAAA\",\"a\":\"govee5075_passive\",\"RSSI\":-76,\"p\":\"0D09475648353037355F32443830030388EC02010509FF88EC0082F8B05800\"}}','test')
    # tasmota.publish.result('{\"DetailsBLE\":{\"mac\":\"A4C138BBBBBB\",\"a\":\"govee5075_active\",\"RSSI\":-83,\"p\":\"0D09475648353037355F32443830030388EC02010509FF88EC0081EBD355001AFF4C000215494E54454C4C495F524F434B535F48575075F2FFC2\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"494207AAAAAA\",\"a\":\"inkbirdth_passive\",\"RSSI\":-83,\"p\":\"0201060302F0FF\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"494207BBBBBB\",\"a\":\"inkbirdth_active\",\"RSSI\":-83,\"p\":\"0201060302F0FF04097370730AFF3E09F11000526A6408\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"494207CCCCCC\",\"a\":\"inkbirdth_active_noH\",\"RSSI\":-83,\"p\":\"0201060302F0FF04097470730AFF5CFA000000C4D54908\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"D4E4A3AAAAAA\",\"a\":\"sbot_temp_passive\",\"RSSI\":-75,\"p\":\"02010609FF5900D4E4A3AAAAAA\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"D4E4A3BBBBBB/1\",\"a\":\"sbot_temp_active\",\"RSSI\":-83,\"p\":\"02010609FF5900D4E4A3BBBBBB11071BC5D5A50200B89FE6114D22000DA2CB0916000D5410640411BC\",\"0x0d00\":\"5410640511BC\"}}','test')
    # tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"A4C1381BXXXX\",\"a\":\"govee5101_test\",\"RSSI\":-91,\"p\":\"0D09475648353130325F44443238030388EC02010509FF0100010182D92164\"}}', 'test')
      if (tasmota.millis()%2) == 1
        tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"D03232XXXXXX/1\",\"a\":\"govee5184_seq1\",\"RSSI\":-83,\"p\":\"0201060303518414FF363E5D01000101BC01860898FFFF06FFFFFFFF"}}','test')
      else
        tasmota.publish_result('{\"DetailsBLE\":{\"mac\":\"D03232XXXXXX/1\",\"a\":\"govee5184_seq2\",\"RSSI\":-81,\"p\":\"0201060303518414FF363E5D01000101BB02860960FFFFC609600898"}}','test')
      end
    fake_print_time = tasmota.millis(5000)
  end
end
tasmota.add_driver(fake_ble)
