#######################################################################
# Blerry = BLE with Berry for Tasmota ESP32
#
# use : `ON System#Boot DO br load('blerry.be') ENDON`
#
# Provides MQTT Discovery and Reporting for BLE Devices
#######################################################################

import json
import path

#######################################################################
# Class for a Blerry Instance
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
    self.devices = []
    for m:self.device_config.keys()
      self.devices.push(Blerry_Device(m, self.device_config[m]))
    end
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

# Blerry_Device
#   generalized representation of a device
class Blerry_Device
  var mac
  var config
  def init(mac, config)
    self.mac = mac
    self.config = config
  end
end

# BLE_AdvData
#   generalized representation of a BLE advertisement from DetailsBLE
class BLE_AdvData
  def init()
    return 0
  end
end

# BLE_AdvElement
#   generalized representation of an element of a BLE advertisement from DetailsBLE
class BLE_AdvElement
  def init()
    return 0
  end
end

blerry = Blerry()