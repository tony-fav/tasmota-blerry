def blerry_handle(device, advert)
  var elements = advert.get_elements_by_type_data(0x16, bytes('1B18'), 0)
  if size(elements)
    var data = elements[0].data[2..]
    var is_stable = (data[1] & (1 << 5)) != 0
    var is_removed  = (data[1] & (1 << 7)) != 0
    if !is_stable && is_removed
      return false
    end

    var weight = data[11..12].get(0, 2)*0.01
    if weight
      var unit = nil
      if data[0] == 0x02
        weight = weight/2.0
        unit = 'kg'
      elif data[0] == 0x03
        unit = 'lbs'
      end
      device.add_sensor_in_range('Weight', weight, nil, unit, 0., nil)
    end

    var got_impedance = (data[1] & (1 << 1)) != 0
    if got_impedance
      var impedance = data[9..10].get(0, 2)
      device.add_sensor_in_range('Impedance', impedance, nil, 'ohm', 0., 3000.)
    end

  end
  return true
end
blerry_active = false
print('BLY: Driver: MiScale2 Loaded')
