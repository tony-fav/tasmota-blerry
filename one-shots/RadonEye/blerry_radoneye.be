import string
import math

def bitval(x, n)
  return (x & (1 << n)) >> n
end

def hack_convert(x) # sloppy sloppy sloppy int to floating point with lots of restrictions
  var exponent = ((x & 0x7F800000) >> 23) - 127
  var mantissa_bits = (x & 0x007FFFFF)
  var mantissa = 1.0
  for i:1..23
    mantissa = mantissa + bitval(mantissa_bits, 23-i)/math.pow(2.0, i)
  end
  return mantissa*math.pow(2.0, exponent)
end

class RadonEyeDriver : Driver
  var mac
  var mac_w_1
  var service 
  var write_char
  var read_char
  var cmnd_time_diff
  var cmnd_time_next
  var last_write_opid
  var last_read_opid

  def init(mac, polling_time) # input in seconds
    # inputs
    self.mac = mac
    self.cmnd_time_diff = polling_time*1000 # ms

    self.last_write_opid = -1
    self.last_read_opid = -1

    # constants    
    self.service = '00001523-1212-efde-1523-785feabcd123'
    self.write_char = '00001524-1212-efde-1523-785feabcd123'
    self.read_char = '00001525-1212-efde-1523-785feabcd123'

    # derivative values
    self.cmnd_time_next = tasmota.millis(self.cmnd_time_diff)
    self.mac_w_1 = self.mac + '/1'

    # register rules
    tasmota.add_rule('BLEOperation', / value, trigger, msg -> self.BLEOperation_callback(value, trigger, msg))
  end

  def every_second()
    if tasmota.millis() > self.cmnd_time_next
      self.last_write_opid = tasmota.cmd(string.format('BLEOp1 m:%s s:%s c:%s w:50 go', self.mac_w_1, self.service, self.write_char))['BLEOp']['opid']
      self.last_read_opid = tasmota.cmd(string.format('BLEOp1 m:%s s:%s c:%s r go', self.mac_w_1, self.service, self.read_char))['BLEOp']['opid']
      self.cmnd_time_next = tasmota.millis(self.cmnd_time_diff)
    end
  end

  def BLEOperation_callback(value, trigger, msg)
    if value['MAC'] != self.mac
      return
    end
    if number(value['opid']) != self.last_read_opid
      return
    end
    if value['state'] != 'DONEREAD'
      return
    end
    var data = bytes(value['read'])
    if data[0..1] != bytes('5010')
      return
    end
    var radonnow = data[2..5]
    if radonnow != bytes('00000000')
      radonnow = hack_convert(radonnow.get(0,4))
      tasmota.publish('tele/tasmota_blerry/radoneye/radonnow', string.format('%g', radonnow), true)
    end
    var radonday = data[6..9]
    if radonday != bytes('00000000')
      radonday = hack_convert(radonday.get(0,4))
      tasmota.publish('tele/tasmota_blerry/radoneye/radonday', string.format('%g', radonday), true)
    end
    var radonmonth = data[10..13]
    if radonmonth != bytes('00000000')
      radonmonth = hack_convert(radonmonth.get(0,4))
      tasmota.publish('tele/tasmota_blerry/radoneye/radonmonth', string.format('%g', radonmonth), true)
    end
  end

end

radoneye_driver = RadonEyeDriver('C67185F1BA3C', 300) # create instance of driver with 300s polling rate
tasmota.add_driver(radoneye_driver)

# {"BLEOperation":{"opid":"15","stat":"3","state":"DONEREAD","MAC":"C67185F1BA3C","svc":"00001523-1212-efde-1523-785feabcd123","char":"00001525-1212-efde-1523-785feabcd123","read":"50100AD7233F0000000000000000040001000000"}}
# tasmota.publish_result('{"BLEOperation":{"opid":"15","stat":"3","state":"DONEREAD","MAC":"C67185F1BA3C","svc":"00001523-1212-efde-1523-785feabcd123","char":"00001525-1212-efde-1523-785feabcd123","read":"50100AD7233F0000000000000000040001000000"}}', 'test')
