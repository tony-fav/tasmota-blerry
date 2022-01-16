#######################################################################
# Blerry = BLE with Berry for Tasmota ESP32
#
# use : `ON System#Boot DO br load('blerry.be') ENDON`
#
# Provides MQTT Discovery and Reporting for BLE Devices
#######################################################################

import json
import path
import string

# dev helper
import introspect
var dir = introspect.members

var blerry_handle
var blerry_active

#######################################################################
# BLE_AdvElement
#######################################################################
class BLE_AdvElement
  var length
  var type
  var data

  def init(l, t, d)
    self.length = l
    self.type = t
    self.data = d
  end
end

#######################################################################
# BLE_AdvData
#######################################################################
class BLE_AdvData
  var elements

  def init(p)
    var i = 0
    var adv_len = 0
    var adv_data = bytes('')
    var adv_type = 0
    self.elements = []
    while i < size(p)
      adv_len = p.get(i,1)
      adv_type = p.get(i+1,1)
      adv_data = p[i+2..i+adv_len]
      self.elements.push(BLE_AdvElement(adv_len, adv_type, adv_data))
      i = i + adv_len + 1
    end
  end

  def get_elements_by_type(t)
    var out = []
    for e:self.elements
      if e.type == t
        out.push(e)
      end
    end
    return out
  end

  def get_elements_by_type_length(t, l)
    var out = []
    for e:self.elements
      if e.type == t && e.length == l
        out.push(e)
      end
    end
    return out
  end

  def get_elements_by_type_length_data(t, l, d, di)
    var out = []
    for e:self.elements
      if e.type == t && e.length == l && e.data[di..di+size(d)-1] == d
        out.push(e)
      end
    end
    return out
  end
end

#######################################################################
# Blerry_Device
#######################################################################
class Blerry_Device
  var mac
  var config
  var alias
  var handle
  var active

  def init(mac, config)
    self.mac = mac
    self.config = config
    self.alias = config['alias']
    self.load_driver()
  end

  def load_driver()
    var model_drivers = 
    {
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
      'WoPresence': 'blerry_model_WoPresence.be'
    }
    var fn = model_drivers[self.config['model']]    
    load(fn)
    self.handle = blerry_handle
    self.active = blerry_active
  end
end

#######################################################################
# Class for Blerry Instance
#######################################################################
class Blerry
  var default_config
  var user_config
  var device_config
  var devices

  def init()
    self.load_default_config()
    self.load_user_config()
    self.setup_device_config()
    self.setup_devices()
    self.setup_packet_rule()
  end

  # Load user config and default config from JSON files
  # Validate JSON with https://jsonformatter.curiousconcept.com/
  # Convert back and form to YAML with https://www.json2yaml.com/
  def load_user_config()  # based on persist module
    var f
    var val
    if path.exists("blerry_user_config.json")
      try
        f = open("blerry_user_config.json", "r")
        val = json.load(f.read())
        f.close()
      except .. as e, m
        if f != nil f.close() end
        raise e, m
      end
      if isinstance(val, map)
        self.user_config = val
      else
        raise "blerry_error", "failed to load blerry_user_config.json"
      end
    else
      raise "blerry_error", "no blerry_user_config.json found"
    end
  end

  def load_default_config()
    self.default_config = 
    {
      'discovery': false,
      'use_lwt': false,
      'via_pubs': false,
      'sensor_retain': false,
      'publish_attributes': false,
      'precision': 
      {
          'Temperature': 2,
          'Humidity': 1,
          'Battery': 0
      }
    }
  end

  # for each device, default then device specific, then override
  def setup_device_config()
    self.device_config = {}
    for m:self.user_config['devices'].keys()
      self.device_config[m] = {}
      for k:self.default_config.keys()
        self.device_config[m][k] = self.default_config[k]
      end
      for k:self.user_config['devices'][m].keys()
        self.device_config[m][k] = self.user_config['devices'][m][k]
      end
      for k:self.user_config['override'].keys()
        self.device_config[m][k] = self.user_config['override'][k]
      end
    end
  end

  def setup_devices()
    var active = false
    self.devices = {}
    for m:self.device_config.keys()
      var bd = Blerry_Device(m, self.device_config[m])
      self.devices[m] = bd
      active = active || bd.active
      tasmota.cmd(string.format('BLEAlias %s=%s', bd.mac, bd.alias))
    end
    if active
      tasmota.cmd('BLEScan0 1')
    end
    tasmota.cmd('BLEDetails4')
  end

  def DetailsBLE_callback(value, trigger, msg)
    var advert = BLE_AdvData(bytes(value['p']))
    print(value, trigger, msg)
    try
      self.devices[value['mac']].handle(advert)
    except .. as e, m
      print('BLY: tried to handle mac =', value['mac'], 'with alias =', value['a'])
      raise e, m
    end
    
    print(value, trigger, msg)
  end

  def setup_packet_rule()
    tasmota.add_rule('DetailsBLE', def (value, trigger, msg) self.DetailsBLE_callback(value, trigger, msg) end)
  end

end

# Blerry_Driver
#   periodic publication of data
#   WebUI display of data
# The goal of using a driver for publication is to rate limit ESP tasks a bit
class Blerry_Driver : Driver
  def init()
  end

  def every_second()
  end

  def every_100ms()
  end

  def every_50ms()
  end
end

blerry = Blerry()