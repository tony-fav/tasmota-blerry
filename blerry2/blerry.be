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

  def init()
    self.load_default_config()
    self.load_user_config()
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

  def load_default_config()  # based on persist module
    var f
    var val
    if path.exists("blerry_default_config.json")
      try
        f = open("blerry_default_config.json", "r")
        val = json.load(f.read())
        f.close()
      except .. as e, m
        if f != nil f.close() end
        raise e, m
      end
      if isinstance(val, map)
        self.default_config = val
      else
        raise "blerry_error", "failed to load blerry_default_config.json"
      end
    else
      raise "blerry_error", "no blerry_default_config.json found"
    end
  end

end

# Blerry_Driver
#   periodic publication of data
#   WebUI display of data
class Blerry_Driver : Driver
  def init()
    return 0
  end
end

# Blerry_Device
#   generalized representation of a device
class Blerry_Device
  var mac
  var config
  def init(mac, config)

    return 0
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



