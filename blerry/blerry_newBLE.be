# https://staars.github.io/site/Bluetooth_MI32/#berry-support
# https://github.com/arendst/Tasmota/pull/14491
import string
var ble, cbp, buf

def byte2string(x)
  return x.tostring()[7..-3]
end

def bytes2string(x)
  var s = ''
  for b:0..size(x)-1
    s = s + byte2string(x[b..b])
  end
  return s
end

def cb(svc, manu)
  var macstr = bytes2string(buf[0..5])
  if buf[6] > 0
    macstr = string.format('%s/%d', macstr, buf[6])
  end
  if !blerry.devices.contains(macstr)
    print('BLY: Heard from unregistered MAC:', macstr)
    return
  end
  var old_format = {
    'mac': macstr,
    'RSSI': buf.geti(7,1),
    'p': bytes2string(buf[9..8+buf[8]]),
    'a': blerry.devices[macstr].alias
  }
  print(old_format)
  blerry.handle_BLE_packet(old_format)
end
buf = bytes(-64)
cbp = tasmota.gen_cb(/s,m-> cb(s,m))
ble = BLE()
ble.adv_cb(cbp,buf)

def newBLE_watchList()
  # Register macs to listen to
  for de:blerry.devices
    var macstr = de.mac
    if size(macstr) == 12
      ble.adv_watch(bytes(macstr))
    elif size(macstr) == 14
      ble.adv_watch(bytes(macstr[0..11]), int(macstr[13]))
    end
    print('BLY: Watching: ', macstr)
  end
end

def newBLE_active()
  # Turn on active scan if required
  tasmota.set_timer(5000, newBLE_watchList)
  for de:blerry.devices
    if de.active
      tasmota.cmd('MI32Option4 1')
      return
    end
  end
end

tasmota.set_timer(5000, newBLE_active)
