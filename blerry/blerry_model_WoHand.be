# Switchbot Bot
# https://github.com/OpenWonderLabs/python-host/wiki/Motion-Sensor-BLE-open-API
# Tested on Bot firmware v4.9
def handle_WoHand(value, trigger, msg)
  if trigger == details_trigger
    var this_device = device_config[value['mac']]
    var p = bytes(value['p'])
    var i = 0
    var adv_len = 0
    var adv_data = bytes('')
    var adv_type = 0
    while i < size(p)
      adv_len = p.get(i,1)
      adv_type = p.get(i+1,1)
      adv_data = p[i+2..i+adv_len]
      if (adv_type == 0x16) && (adv_len == 0x06) && (adv_data[0..1] == bytes('000D'))
        var this_data = [
          (adv_data[3] & 0x80) >> 7, # 0 = Press, 1 = Switch
          (adv_data[3] & 0x40) >> 6, # 0 = On, 1 = Off
          (adv_data[3] & 0x10) >> 4, # 1 = We did the last thing we got asked to
          (adv_data[4] & 0x7F) >> 0, # Battery
          ]
        if this_data[0]
          this_data[0] = 'Switch Mode'
        else
          this_data[0] = 'Press Mode'
        end
        if this_data[1]
          this_data[1] = 'Off'
        else
          this_data[1] = 'On'
        end
        if this_data[2]
          this_data[2] = 'Success'
        else
          this_data[2] = 'Fail'
        end
        this_data[3] = string.format('Battery %d%%', this_data[3])
        print('SB', this_data)
      end
      i = i + adv_len + 1
    end
  end
end

def WoHand_write(mac, payload)
  var base = 'BLEOp1 m:%s s:cba20d00-224d-11e6-9fb8-0002a5d5c51b c:cba20002-224d-11e6-9fb8-0002a5d5c51b w:57%s n:cba20003-224d-11e6-9fb8-0002a5d5c51b go'
  tasmota.cmd(string.format(base, mac, payload))
end

def WoHand_setModePress(mac)
  WoHand_write(mac, '036400')
end
def WoHand_setModePressInv(mac)
  WoHand_write(mac, '036401')
end
def WoHand_setModeSwitch(mac)
  WoHand_write(mac, '036410')
end
def WoHand_setModeSwitchInv(mac)
  WoHand_write(mac, '036411')
end
def WoHand_doToggle(mac)
  WoHand_write(mac, '01')
end
def WoHand_doOn(mac)
  WoHand_write(mac, '0101')
end
def WoHand_doOff(mac)
  WoHand_write(mac, '0102')
end
def WoHand_doHold(mac)
  WoHand_write(mac, '0103')
end
def WoHand_doClose(mac)
  WoHand_write(mac, '0104')
end

# br WoHand_setModePress('D81E7A38ED1D/1')
# br WoHand_setModePressInv('D81E7A38ED1D/1')
# br WoHand_setModeSwitch('D81E7A38ED1D/1')
# br WoHand_setModeSwitchInv('D81E7A38ED1D/1')
# br WoHand_doToggle('D81E7A38ED1D/1')
# br WoHand_doOn('D81E7A38ED1D/1')
# br WoHand_doOff('D81E7A38ED1D/1')
# br WoHand_doHold('D81E7A38ED1D/1')
# br WoHand_doClose('D81E7A38ED1D/1')

# map function into handles array
device_handles['WoHand'] = handle_WoHand
require_active['WoHand'] = true