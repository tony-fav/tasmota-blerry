def blerry_op_handle(device, value)
  if value['state'] == 'DONENOTIFIED'
    var data = bytes(value['notify'])
    device.add_attribute('FailCount', 0)
    if data[0] == 0x0A
      device.add_sensor_in_range('Temperature', data.geti(6, -2)/10.0, 'temperature', '°C', 0, nil)
      device.add_sensor_in_range('TVOC', data.get(10, -2),  'volatile_organic_compounds', 'ppb', 0, 0x3FFF)
      device.add_sensor_in_range('HCHO', data.get(12, -2),  nil, 'ppb', 0, 0x3FFF)
      device.add_sensor_in_range('CO2', data.get(16, -2), 'carbon_dioxide', 'ppm', 450, nil)
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
    return string.format("br blerry_BLEOpWN.setAndGo('%s', 'fff0', 'fff1', 'ab','fff4')", mac)
  else
    return string.format('BLEOp1 m:%s s:fff0 c:fff1 n:fff4 w:ab go', mac)
  end
end
print('BLY: Driver: WP6003 Loaded')

# br blerry_BLEOpWN.setAndGo('60030394342A', 'fff0', 'fff1', 'ab','fff4')
# BLEOp1 m:60030394342A s:fff0 c:fff1 n:fff4 w:ab go
