def time()
  return tasmota.time_str(tasmota.rtc()['local'])
end

class BlerryPoll
  var mac
  var mactype
  var write_svc
  var write_chr
  var write_val
  var write_res
  var notify_svc
  var notify_chr
  var cbp
  var buf
  var ble


  def init(mac, mactype, write_svc, write_chr, write_val, write_res, notify_svc, notify_chr)
    # inputs
    self.mac = bytes(mac)
    self.mactype = int(mactype)
    self.write_svc = write_svc
    self.write_chr = write_chr
    self.write_val = bytes(write_val)
    self.write_res = int(write_res)
    self.notify_svc = notify_svc
    self.notify_chr = notify_chr

    # setup
    self.cbp = tasmota.gen_cb(/e,o,u->self.cb(e,o,u))
    self.buf = bytes(-20)
    self.ble = BLE()
    self.ble.conn_cb(self.cbp, self.buf)
    self.ble.set_MAC(self.mac, self.mactype)
  end

  def subscribe()
    self.ble.set_svc(self.notify_svc)
    self.ble.set_chr(self.notify_chr)
    self.ble.run(3)
  end

  def write()
    self.ble.set_svc(self.write_svc)
    self.ble.set_chr(self.write_chr)
    var N = size(self.write_val)
    self.buf[0] = N
    for n:1..N
      self.buf[n] = self.write_val[n-1]
    end
    self.ble.run(2, self.write_res)
  end

  def disconnect()
    print("DCON:", time(), "Disconnecting...")
    self.ble.run(5)
  end
  
  def cb(err, op, uuid)
    if op == 3
      if err == 0
        print("CALB:", time(), "Subscribed Successfully")
        self.write()
      else
        print("CALB:", time(), "Failed to Subscribe, Re-Trying in 1s")
        tasmota.set_timer(1000, /->self.subscribe())
      end
    elif op == 5 && err == 2
      print("CALB:", time(), "Disconnected Successfully")
      print('------------------------------------------')
    elif op == 103
      var N = self.buf[0]
      var rbuf = self.buf[1..N]
      print("CALB:", time(), err, op, uuid, 'buf:', rbuf)
      self.disconnect()
    else
      print("CALB:", time(), err, op, uuid, 'raw buf:', self.buf)
    end
  end

  def poll()
    self.subscribe()
  end
end

wp6003_op = BlerryPoll('60030394342A', 0, 'fff0', 'fff1', 'ab', 0, 'fff0', 'fff4')
wp6003_op.poll()
