def blerry_handle(device, advert)
  print('-- ' + device.mac + ' -- ' + device.alias + ' --')
  for e:advert.elements
    print(string.format('Length: 0x%02X, Type: 0x%02X, Data: %s', e.length, e.type, e.data))
  end
  return true
end
blerry_active = true
