def blerry_handle(device, advert)
  print('-- ' + device.mac + ' -- ' + device.alias + ' --')
  for e:advert.elements
    print(string.format('Length: 0x%02X, Type: 0x%02X, Data: %s', e.length, e.type, e.data))
    # https://github.com/berry-lang/berry/wiki/Chapter-7#get-geti-methods
    #   Read a 1/2/4 bytes value from any offset in the bytes array. 
    #   The standard mode is little endian, 
    #   if you specify a negative size it enables big endian. 
    #   get returns unsigned values, while geti returns signed values.
  end
  return true
end
blerry_active = true
