# https://staars.github.io/site/Bluetooth_MI32/#berry-support
# https://github.com/arendst/Tasmota/pull/14491
import string
var ble, cbp, buf

blerry.mi32ble = true

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
  # print(old_format)
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

# Create a BLEOp1 substitute
class BLEOpWN
  var macstr
  var mac
  var mactype
  var svc
  var write_chr
  var write_val
  var notify_chr
  var cbp
  var buf
  var ble

  def init()
    self.cbp = tasmota.gen_cb(/e,o,u->self.cb(e,o,u))
    self.buf = bytes(-64)
    self.ble = BLE()
  end

  def set(macstr, svc, write_chr, write_val, notify_chr)
    # inputs
    self.macstr = macstr
    if size(macstr) == 14
      self.mac = bytes(macstr[0..11])
      self.mactype = int(macstr[13])
    else
      self.mac = bytes(macstr[0..11])
      self.mactype = 0
    end
    self.svc = svc
    self.write_chr = write_chr
    self.write_val = bytes(write_val)
    self.notify_chr = notify_chr

    # setup
    self.ble.conn_cb(self.cbp, self.buf)
    self.ble.set_MAC(self.mac, self.mactype)
  end

  def setAndGo(macstr, svc, write_chr, write_val, notify_chr)
    self.set(macstr, svc, write_chr, write_val, notify_chr)
    self.go()
  end

  def go()
    self.ble.set_svc(self.svc)
    self.ble.set_chr(self.notify_chr)
    self.ble.run(3)
  end

  def write()
    self.ble.set_svc(self.svc)
    self.ble.set_chr(self.write_chr)
    var N = size(self.write_val)
    self.buf[0] = N
    for n:1..N
      self.buf[n] = self.write_val[n-1]
    end
    self.ble.run(2, 1)
  end

  def cb(err, op, uuid)
    if err == 0
      if op == 3
        self.write()
      elif op == 103
        var N = self.buf[0]
        var rbuf = self.buf[1..N]
        self.ble.run(5)
        var value = {
          'MAC': self.macstr,
          'state': 'DONENOTIFIED',
          'notify': bytes2string(rbuf)
        }
        blerry.handle_BLEOp_packet(value)
      end
    else
      if op == 5 && err == 2
        # disconnected fine
      elif op == 5 && err == 1
        # some connection error
      else
        print("BLY: BlerryPoll Error", err, op, uuid, 'raw buf:', self.buf)
        self.ble.run(5)
      end
    end
  end
end

var blerry_BLEOpWN = BLEOpWN()

# BLEOpWN('60030394342A', 'fff0', 'fff1', 'ab','fff4').go()
# {"BLEOperation":{"opid":"2","stat":"7","state":"DONENOTIFIED","MAC":"60030394342A","svc":"0xfff0","char":"0xfff1","notifychar":"0xfff4","write":"AB","notify":"0A160316131700D7080000B9001C01000263"}}
