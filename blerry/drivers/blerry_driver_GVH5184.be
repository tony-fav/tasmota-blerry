def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_length(0xFF, 0x14)
  if size(elements)
    var data = elements[0].data
    var probe_labels = ['_1_', '_2_']
    if data[8] == 2
      probe_labels = ['_3_', '_4_']
    end
    device.add_sensor('Battery', (data[7] & 0x7F), 'battery', '%')
    def f_t(x) # function for unavailable temps
      if x == 0xFFFF
        return 'unavailable'
      else
        return x/100.0
      end
    end
    for probe_idx:0..1
      var probe_label = probe_labels[probe_idx]
      var offset = 5*probe_idx
      device.add_binary_sensor('Probe' + probe_label + 'Status', blerry_helpers.bitval(data[offset + 9], 7), 'plug')
      device.add_binary_sensor('Probe' + probe_label + 'Alarm',  blerry_helpers.bitval(data[offset + 9], 6), 'heat')
      device.add_sensor('Probe' + probe_label + 'Temp', f_t(data.get(offset + 10, -2)),  'temperature', '°C')
      device.add_sensor('Probe' + probe_label + 'Target', f_t(data.get(offset + 12, -2)),  'temperature', '°C')
    end
    return true
  else
    return false
  end
end
blerry_active = false
print('BLR: Driver: GVH5184 Loaded')
