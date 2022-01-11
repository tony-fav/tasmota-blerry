def handle_ignore(value, trigger, msg)
  return 0
end
device_handles['ignore'] = handle_ignore
require_active['ignore'] = false