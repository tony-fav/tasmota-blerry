def handle_GVH5184(value, trigger, msg)
  if trigger == details_trigger
    var this_device = device_config[value['mac']]
    var p = bytes(value['p'])
    var i = 0
    var adv_len = 0
    var adv_data = bytes('')
    var adv_type = 0
    while i < size(p)
      adv_len = p.get(i,1)
      adv_type = p.get(i+1,1)
      adv_data = p[i+2..i+adv_len]
      if (adv_type == 0xFF) && (adv_len == 0x14)
          var this_data = [adv_data.get(10, -2), adv_data.get(12, -2), adv_data.geti(14, -2)]
          print(this_data)
      end
      i = i + adv_len + 1
    end
  end
end
  
# map function into handles array
device_handles['GVH5184'] = handle_GVH5184
require_active['GVH5184'] = false
