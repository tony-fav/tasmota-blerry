def blerry_op_handle(device, value)
  if value['state'] == 'DONENOTIFIED'
    var data = bytes(value['notify'])
    if data[0] == 0x0A
      device.add_sensor('Temperature', data.geti(6, -2)/10.0,  'temperature', '°C')
      device.add_sensor('TVOC', data.get(10, -2)/1000.0,  'volatile_organic_compounds', 'ppm')
      device.add_sensor('HCHO', data.get(12, -2)/1000.0,  nil, 'ppm')
      device.add_sensor('CO2', data.get(16, -2),  'carbon_dioxide', 'ppm')
    end
  end
end

def blerry_op_cmd(mac)
  return string.format('BLEOp1 m:%s s:fff0 c:fff1 n:fff4 w:ab go', mac)
end
