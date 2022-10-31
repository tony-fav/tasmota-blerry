def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length(0xFF, 0x13)
  if size(elements)
    var data = elements[0].data[10..]
    def f_t(x) # function for unavailable temps
      if x >= 0xF6FF
        return 'unavailable'
      else
        return x/10.0
      end
    end
    for probe_idx:0..3
      device.add_sensor('Probe_' + str(probe_idx+1) + '_Temp', f_t(data.get(2*probe_idx, 2)),  'temperature', '°C')
    end
    return true
  else
    return false
  end
end
blerry_active = false
print('BLR: Driver: iBBQ4 Loaded')
