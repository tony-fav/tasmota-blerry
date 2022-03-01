import json
var fake_print_time = tasmota.millis(5000)
fake_packet_options = [
  '0D09475648353037355F32443830030388EC02010509FF88EC0082F8B05800',
  '0D09475648353037355F32443830030388EC02010509FF88EC0081EBD355001AFF4C000215494E54454C4C495F524F434B535F48575075F2FFC2',
  '0D09475648353130325F44443238030388EC02010509FF0100010182D92164',
]

fake_ble = Driver()
fake_ble.every_second = def ()
  if tasmota.millis() > fake_print_time
    var msg = {'DetailsBLE': {}}
    msg['DetailsBLE']['mac'] = 'A4C138AAAAAA'
    msg['DetailsBLE']['a'] = 'dev_GVH5075'
    msg['DetailsBLE']['RSSI'] = -1
    var idx = tasmota.millis() % size(fake_packet_options)
    msg['DetailsBLE']['p'] = fake_packet_options[idx]
    tasmota.publish_result(json.dump(msg), 'BLY')
    fake_print_time = tasmota.millis(5000)
  end
end
tasmota.add_driver(fake_ble)
