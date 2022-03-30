def blerry_op_handle(device, value)
  if value['state'] == 'DONENOTIFIED'
    var data = bytes(value['notify'])
    device.add_attribute('FailCount', 0)
    if data[0] == 0x0A
      device.add_true_sensor('Temperature', data.geti(6, -2)/10.0, 'temperature', '°C')
      device.add_true_sensor('TVOC', data.get(10, -2),  'volatile_organic_compounds', 'ppb')
      device.add_true_sensor('HCHO', data.get(12, -2),  nil, 'ppb')
      device.add_true_sensor('CO2', data.get(16, -2),  'carbon_dioxide', 'ppm')
    end
  else
    var cnt = device.get_attribute('FailCount')
    if cnt
      device.add_attribute('FailCount', cnt.value+1)
    else
      device.add_attribute('FailCount', 1)
    end
  end
  device.add_sensor('OpState', value['state'], nil, '')
  device.add_sensor('OpFailureCount', device.get_attribute('FailCount').value, nil, '')
end

def blerry_op_cmd(mac)
  if blerry.mi32ble
    return string.format("br BLEOpWN('%s', 'fff0', 'fff1', 'ab','fff4').go()", mac)
  else
    return string.format('BLEOp1 m:%s s:fff0 c:fff1 n:fff4 w:ab go', mac)
  end
end
print('BLY: Driver: WP6003 Loaded')

# br BLEOpWN('60030394342A', 'fff0', 'fff1', 'ab','fff4').go()
