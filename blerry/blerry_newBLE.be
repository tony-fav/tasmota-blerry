import string
var ble, cbp, buf
def cb()
  var old_format = {}
  var macstr = buf[0..5].tostring()[7..-3] # as a string
  if buf[6] > 0
    macstr = string.format('%s/%d', macstr, buf[6])
  end
  old_format['mac'] = macstr

  if !blerry.devices.contains(macstr)
    return
  end

  old_format['RSSI'] = buf.geti(9,1)

  var svc_len = buf[10]
  if svc_len
    var p = bytes('00160000') .. buf[11..10+svc_len]
    # print(p)
    p[0] = svc_len + 3
    p[2] = buf[7]
    p[3] = buf[8]
    old_format['p'] = p.tostring()[7..-3]
  else
    var man_len = buf[11]
    if man_len
      var p = bytes('00FF') .. buf[12..11+man_len]
      p[0] = man_len + 1
      old_format['p'] = p.tostring()[7..-3]
    else
      old_format['p'] = ''
    end
  end
  # print(old_format)
  old_format['a'] = 'noAliasNewBLE'
  blerry.handle_BLE_packet(old_format)
end

buf = bytes(-64)
cbp = tasmota.gen_cb(/-> cb())
ble = BLE()
ble.adv_cb(cbp,buf)

# ble.adv_cb(0)
