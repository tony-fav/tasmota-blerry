# https://github.com/saso5/wp6003/blob/main/wp6003.py
# https://github.com/saso5/saso5.github.io/blob/master/WP6003-air-box/index.html
class WP6003 : Driver
  var ble, cbp, buf

  def init()
    self.cbp = tasmota.gen_cb(/e,o,u-> self.cb(e,o,u))
    self.buf = bytes(-256)
    self.ble = BLE()
    self.ble.conn_cb(self.cbp,self.buf)
    var _mac = "60030394342A" 
    self.ble.set_MAC(bytes(_mac),0)
    self.connect()
  end

  def connect()
    self.ble.set_svc("fff0")
    self.ble.set_chr("fff4")
    self.ble.run(3)
  end

  def handle_notification()
    if self.buf[0] == 0x12
      var data = self.buf[1..18]
      print('data: ', data)
      # print('   time: 20', data[1], "/", data[2], "/", data[3], " ", data[4], ":", data[5])
      print('  tempC: ', data.geti(6, -2)/10)
      print('  tempF: ', data.get(6, -2)/10*1.8 + 32.0)
      print('   tvoc: ', data.get(10, -2)/1000.0)
      print('   hcho: ', data.get(12, -2)/1000.0)
      print('    co2: ', data.get(16, -2))
    else
      print('got buf: ', self.buf[0..18])
    end
  end

  def cb(error,op,uuid)
    if error == 0
      if op == 3
          self.handle_notification()
      end
      return
    else
      print('error: ', error)
      self.connect()
    end
  end

end

wp6003 = WP6003()
tasmota.add_driver(wp6003)
