# https://staars.github.io/site/Bluetooth_MI32/#berry-support
# https://github.com/arendst/Tasmota/pull/14491
import string
var ble, cbp, buf
def bytes2string(x)
  return x.tostring()[7..-3]
end
def cb(svc, manu)
  var macstr = bytes2string(buf[0..5])
  if buf[6] > 0
    macstr = string.format('%s/%d', macstr, buf[6])
  end
  if !blerry.devices.contains(macstr)
    return
  end
  var old_format = {
    'mac': macstr,
    'RSSI': buf.geti(7,1),
    'p': bytes2string(buf[9..8+buf[8]]),
    'a': 'noAliasNewBLE'
  }
  print(old_format)
  blerry.handle_BLE_packet(old_format)
end
buf = bytes(-64)
cbp = tasmota.gen_cb(/s,m-> cb(s,m))
ble = BLE()
ble.adv_cb(cbp,buf)
