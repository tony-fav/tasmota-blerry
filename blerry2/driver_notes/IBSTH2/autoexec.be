import json
var fake_print_time = tasmota.millis(5000)
fake_packet_options = [
  '0201060302F0FF',
  '0201060302F0FF04097370730AFF3E09F11000526A6408',
  '0201060302F0FF04097470730AFF5CFA000000C4D54908',
]

fake_ble = Driver()
fake_ble.every_second = def ()
  if tasmota.millis() > fake_print_time
    var msg = {'DetailsBLE': {}}
    msg['DetailsBLE']['mac'] = '494207AAAAAA'
    msg['DetailsBLE']['a'] = 'dev_IBSTH2'
    msg['DetailsBLE']['RSSI'] = -1
    var idx = tasmota.millis() % size(fake_packet_options)
    msg['DetailsBLE']['p'] = fake_packet_options[idx]
    tasmota.publish_result(json.dump(msg), 'BLY')
    fake_print_time = tasmota.millis(5000)
  end
end
tasmota.add_driver(fake_ble)
