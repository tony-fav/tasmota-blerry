def blerry_handle(device, advert)
  var elements_ATC = advert.get_elements_by_type_length_data(0x16, 16, bytes('1A18'), 0)
  var elements_PVVX = advert.get_elements_by_type_length_data(0x16, 18, bytes('1A18'), 0)
  var is_pvvx
  var adv_data
  if size(elements_PVVX)
    is_pvvx = true
    adv_data = elements_PVVX[0].data
  elif size(elements_ATC)
    is_pvvx = false
    adv_data = elements_ATC[0].data
  else
    return false
  end
  return true
end
blerry_active = false