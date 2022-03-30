import string

class WP6003Driver : Driver
  var mac
  var base_topic
  var service 
  var write_chr
  var notify_chr
  var cmnd_time_diff
  var cmnd_time_next
  var last_opid
  var fail_count

  def init(mac, polling_time, base_topic) # input in seconds
    # inputs
    self.mac = mac
    self.cmnd_time_diff = polling_time*1000 # ms
    self.base_topic = base_topic

    self.last_opid = -1

    # constants
    self.service = 'fff0'
    self.write_chr = 'fff1'
    self.notify_chr = 'fff4'

    self.fail_count = 0

    # derivative values
    self.cmnd_time_next = tasmota.millis()

    # register rules
    tasmota.add_rule('BLEOperation', / value, trigger, msg -> self.BLEOperation_callback(value, trigger, msg))
  end

  def every_second()
    if tasmota.millis() > self.cmnd_time_next
      self.last_opid = tasmota.cmd(string.format('BLEOp1 m:%s s:%s c:%s n:%s w:ab go', self.mac, self.service, self.write_chr, self.notify_chr))['BLEOp']['opid']
      self.cmnd_time_next = tasmota.millis(self.cmnd_time_diff)
    end
  end

  def BLEOperation_callback(value, trigger, msg)
    if value['MAC'] != self.mac
      return
    end
    if number(value['opid']) != self.last_opid
      return
    end
    if value['state'] != 'DONENOTIFIED'
      self.fail_count = self.fail_count + 1
      self.cmnd_time_next = tasmota.millis(30*1000) # retry
      return
    end
    var data = bytes(value['notify'])
    print('fail count: ', self.fail_count)
    self.fail_count = 0
    print('data: ', data)
    if data[0] == 0x0A
      tasmota.publish(self.base_topic + 'temp', string.format('%g', data.geti(6, -2)/10.0), true)
      tasmota.publish(self.base_topic + 'tvoc', string.format('%g', data.get(10, -2)/1000.0), true)
      tasmota.publish(self.base_topic + 'hcho', string.format('%g', data.get(12, -2)/1000.0), true)
      tasmota.publish(self.base_topic + 'co2', string.format('%d', data.get(16, -2)), true)
    end
  end

end

airbox_driver = WP6003Driver('60030394342A', 300, 'tele/tasmota_blerry/WP6003_60030394342A/') # create instance of driver with 300s polling rate
tasmota.add_driver(airbox_driver)
print('added driver')

# BLEOp1 m:60030394342A s:fff0 c:fff1 n:fff4 w:ab go
