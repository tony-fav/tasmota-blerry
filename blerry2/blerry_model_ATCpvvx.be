def blerry_handle(advert)
  var elements_ATC = advert.get_elements_by_type_length_data(0x16, 16, bytes('1A18'), 0)
  var elements_PVVX = advert.get_elements_by_type_length_data(0x16, 18, bytes('1A18'), 0)
  if size(elements_ATC)
    print('got ATC')
  end
  if size(elements_PVVX)
    print('got PVVX')
  end
end
blerry_active = false