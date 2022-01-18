
# ----------- IMPORTS ----------
import math
import string
import json

# ----------- HELPERS ----------
def round(x, p)
  return math.ceil(math.pow(10.0, p)*x)/math.pow(10.0, p)
end
def get_dewpoint(t, h) # temp, humidity, precision
  var gamma = math.log(h / 100.0) + 17.62 * t / (243.5 + t)
  return (243.5 * gamma / (17.62 - gamma))
end
def string_replace(x, y, r)
  var z = x[0..]
  var n = size(y)
  var m = size(r)
  var k = 0
  while k < size(z)
    var j = string.find(z, y, k)
    if j < 0
      break
    end
    if j > 0
      z = z[0..j-1] + r + z[j+n..]
    else
      z = r + z[j+n..]
    end
    k = j+m
  end
  return z
end

# ----------- BLERRY -----------
if base_topic[-1] == '/' # allow / at the end but remove it here
  base_topic = base_topic[0..-2]
end
var device_config = {}
var details_trigger = 'DetailsBLE'
if old_details
  details_trigger = 'details'
end

# Get this device's topic info
var device_topic = tasmota.cmd('Status')['Status']['Topic']
var cmnd_prefix = tasmota.cmd('Prefix1')['Prefix1']
var stat_prefix = tasmota.cmd('Prefix2')['Prefix2']
var tele_prefix = tasmota.cmd('Prefix3')['Prefix3']
var full_topic_f = tasmota.cmd('FullTopic')['FullTopic']
var hostname = tasmota.cmd('Status 5')['StatusNET']['Hostname']
var device_tele_topic = string_replace(string_replace(full_topic_f, '%prefix%', tele_prefix), '%topic%', device_topic)
if device_tele_topic[-1] == '/' # allow / at the end but remove it here
  device_tele_topic = device_tele_topic[0..-2]
end

def publish_sensor_discovery(mac, prop, dclass, unitm)
  var item = device_config[mac]
  var prefix = '{'
  if item['use_lwt']
    prefix = prefix + string.format('"avty_t\": \"%s/LWT\",\"pl_avail\": \"Online\",\"pl_not_avail\": \"Offline\",', device_tele_topic)
  else
    prefix = prefix + '\"avty\": [],'
  end
  prefix = prefix + string.format('\"dev\":{\"ids\":[\"blerry_%s\"],\"name\":\"%s\",\"mf\":\"blerry\",\"mdl\":\"%s\",\"via_device\":\"%s\"},', item['alias'], item['alias'], item['model'], hostname)
  prefix = prefix + string.format('\"exp_aft\": 600,\"json_attr_t\": \"%s/%s\",\"stat_t\": \"%s/%s\",', base_topic, item['alias'], base_topic, item['alias'])
  tasmota.publish(string.format('homeassistant/sensor/blerry_%s/%s/config', item['alias'], prop), prefix + string.format('\"dev_cla\": \"%s\",\"unit_of_meas\": \"%s\",\"name\": \"%s %s\",\"uniq_id\": \"blerry_%s_%s\",\"val_tpl\": \"{{ value_json.%s }}\"}', dclass, unitm, item['alias'], prop, item['alias'], prop, prop), discovery_retain)
end

def publish_binary_sensor_discovery(mac, prop, dclass)
  var item = device_config[mac]
  var prefix = '{'
  if item['use_lwt']
    prefix = prefix + string.format('"avty_t\": \"%s/LWT\",\"pl_avail\": \"Online\",\"pl_not_avail\": \"Offline\",', device_tele_topic)
  else
    prefix = prefix + '\"avty\": [],'
  end
  prefix = prefix + string.format('\"dev\":{\"ids\":[\"blerry_%s\"],\"name\":\"%s\",\"mf\":\"blerry\",\"mdl\":\"%s\",\"via_device\":\"%s\"},', item['alias'], item['alias'], item['model'], hostname)
  prefix = prefix + string.format('\"exp_aft\": 600,\"json_attr_t\": \"%s/%s\",\"stat_t\": \"%s/%s\",', base_topic, item['alias'], base_topic, item['alias'])
  if dclass != 'none'
    prefix = prefix + string.format('\"dev_cla\": \"%s\",', dclass)
  end
  tasmota.publish(string.format('homeassistant/binary_sensor/blerry_%s/%s/config', item['alias'], prop), prefix + string.format('\"name\": \"%s %s\",\"uniq_id\": \"blerry_%s_%s\",\"val_tpl\": \"{{ value_json.%s }}\"}', item['alias'], prop, item['alias'], prop, prop), discovery_retain)
end

# Build complete device config maps
for mac:user_config.keys()
  device_config[mac] = {}
  
  # copy in defaults and data storage items first
  for item:default_config.keys()
    device_config[mac][item] = default_config[item]
  end
  device_config[mac]['last_p'] = bytes('')
  device_config[mac]['done_disc'] = false
  device_config[mac]['done_extra_disc'] = false

  # override with device specific config
  for item:user_config[mac].keys()
    device_config[mac][item] = user_config[mac][item]
  end

  # override with global override
  for item:override_config.keys()
    device_config[mac][item] = override_config[item]
  end
end

# Load model handle functions only if used
var model_drivers = {'GVH5074'   : 'blerry_model_GVH5074.be',
                     'GVH5075'   : 'blerry_model_GVH5075.be',
                     'GVH5072'   : 'blerry_model_GVH5075.be',
                     'GVH5101'   : 'blerry_model_GVH5075.be',
                     'GVH5102'   : 'blerry_model_GVH5075.be',
                     'GVH5182'   : 'blerry_model_GVH5182.be',
                     'GVH5183'   : 'blerry_model_GVH5183.be',
                     'GVH5184'   : 'blerry_model_GVH5184.be',
                     'ATCpvvx'   : 'blerry_model_ATCpvvx.be',
                     'ATC'       : 'blerry_model_ATCpvvx.be',
                     'pvvx'      : 'blerry_model_ATCpvvx.be',
                     'ATCmi'     : 'blerry_model_ATCmi.be',
                     'IBSTH1'    : 'blerry_model_IBSTH2.be',
                     'IBSTH2'    : 'blerry_model_IBSTH2.be',
                     'WoSensorTH': 'blerry_model_WoSensorTH.be',
                     'WoContact' : 'blerry_model_WoContact.be',
                     'WoPresence': 'blerry_model_WoPresence.be'}
var models = {}
for mac:user_config.keys()
  models[model_drivers[device_config[mac]['model']]] = true
end

var device_handles = {}
var require_active = {}
for m:models.keys()
  load(m)
end

# Register Aliases with Tasmota and Register Handle Functions
var setup_active = false
for mac:user_config.keys()
  device_config[mac]['handle'] = device_handles[device_config[mac]['model']]
  tasmota.cmd(string.format('BLEAlias %s=%s', mac, device_config[mac]['alias']))
  setup_active = setup_active || require_active[device_config[mac]['model']]
end
if setup_active
  tasmota.cmd('BLEScan0 1')
end

# Enable BLEDetails for All Aliased Devices and Make Rule
tasmota.cmd('BLEDetails4')
def DetailsBLE_callback(value, trigger, msg)
  device_config[value['mac']]['handle'](value, trigger, msg)
end
tasmota.add_rule(details_trigger, DetailsBLE_callback)
