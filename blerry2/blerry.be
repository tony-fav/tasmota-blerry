#######################################################################
# Blerry = BLE with Berry for Tasmota ESP32
#
# use : `ON System#Boot DO br load('blerry.be') ENDON`
#
# Provides MQTT Discovery and Reporting for BLE Devices
#######################################################################

var blerry_version = 'v0.2.0-dev'

# TODO
#   Add keep alive publications
#   Make Drivers into Classes so they can have some static methods
#   Port V1 Drivers to V2
      # 'GVH5182'   : 'blerry_driver_GVH5182.be',
      # 'GVH5183'   : 'blerry_driver_GVH5183.be',
      # 'GVH5184'   : 'blerry_driver_GVH5184.be',
      # 'ATCmi'     : 'blerry_driver_ATCmi.be',
      # 'WoSensorTH': 'blerry_driver_WoSensorTH.be',
      # 'WoContact' : 'blerry_driver_WoContact.be',
      # 'WoPresence': 'blerry_driver_WoPresence.be',

#######################################################################
# Module Imports
#######################################################################

import math
import json
import path
import string

if path.exists('blerry_setup.be')
  path.remove('blerry_setup.be')
end
if path.exists('blerry_setup.bec')
  path.remove('blerry_setup.bec')
end

#######################################################################
# Helpers
#######################################################################

class blerry_helpers
  static def round(x, p)
    return math.ceil(math.pow(10.0, p)*x)/math.pow(10.0, p)
  end

  static def get_dewpoint(t, h) # temp, humidity
    var gamma = math.log(h / 100.0) + 17.62 * t / (243.5 + t)
    return (243.5 * gamma / (17.62 - gamma))
  end

  static def string_replace(x, y, r)
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

  static def string_upper(x)
    var y = ''
    for i:0..size(x)-1
      var b = string.byte(x[i])
      if b >= 97 && b <= 122
        b = b - 32
      end
      y = y + string.char(b)
    end
    return y
  end

  static def bitval(x, i)
    return (x & (1 << i)) >> i
  end

  static def twos_complement(n, w)
    if n & (1 << (w - 1))
      n = n - (1 << w)
    end
    return n
  end

  static def cmd_set_device(cmd, idx, payload, payload_json)
    var f = open("blerry_config.json", "r")
    var config = json.load(f.read())
    f.close()
    var new_dev = json.load(payload)
    for m:new_dev.keys()
      config['devices'][m] = new_dev[m]
    end
    f = open("blerry_config.json", "w")
    f.write(json.dump(config))
    f.close()
    tasmota.resp_cmnd_done()
  end

  static def cmd_get_device(cmd, idx, payload, payload_json)
    var f = open("blerry_config.json", "r")
    var config = json.load(f.read())
    f.close()
    tasmota.resp_cmnd_str(json.dump({payload: config['devices'][payload]}))
  end
  
  static def cmd_del_device(cmd, idx, payload, payload_json)
    var f = open("blerry_config.json", "r")
    var config = json.load(f.read())
    f.close()
    var new_dev = json.load(payload)
    config['devices'].remove(payload)
    f = open("blerry_config.json", "w")
    f.write(json.dump(config))
    f.close()
    tasmota.resp_cmnd_done()
  end

  static def cmd_set_config(cmd, idx, payload, payload_json)
    var config = json.load(payload)
    var f = open("blerry_config.json", "w")
    f.write(json.dump(config))
    f.close()
    tasmota.resp_cmnd_done()
  end

  static def cmd_get_config(cmd, idx, payload, payload_json)
    var f = open("blerry_config.json", "r")
    var config = json.load(f.read())
    f.close()
    tasmota.resp_cmnd_str(json.dump(config))
  end

  static def cmd_del_config(cmd, idx, payload, payload_json)
    var f = open("blerry_config.json", "w")
    f.write(json.dump({'devices':{}}))
    f.close()
    tasmota.resp_cmnd_done()
  end

  static def download_file(file_name, url)
    var cl = webclient()
    cl.begin(url)
    var r = cl.GET()
    if r != 200
      print('error')
      return false
    end
    var s = cl.get_string()
    cl.close()
    var f = open(file_name, 'w')
    f.write(s)
    f.close()
    return true
  end

  static def download_driver(driver_fname)
    var url = 'https://raw.githubusercontent.com/tony-fav/tasmota-blerry/dev-blerry2/blerry2/' + driver_fname
    return blerry_helpers.download_file(driver_fname, url)
  end

  static def ensure_driver_exists(driver_fname)
    if !path.exists(driver_fname)
      if blerry_helpers.download_driver(driver_fname)
        print('downloaded driver successfully', driver_fname)
        return true
      else
        print('could not download driver automatically', driver_fname)
        return false
      end
    end
  end
end

#######################################################################
# Dev helpers bc I overuse dir when coding Python
#######################################################################

import introspect
var dir = introspect.members

#######################################################################
# Required Globals for Driver Loading
#######################################################################

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

  def get_elements_by_type_data(t, d, di)
    var out = []
    for e:self.elements
      if e.type == t && e.data[di..di+size(d)-1] == d
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
# Blerry_Attribute
#######################################################################
class Blerry_Attribute
  var name
  var value

  def init(name, value)
    self.name = name
    self.value = value
  end
end

#######################################################################
# Blerry_Sensor
#######################################################################
class Blerry_Sensor
  var name
  var dev_cla
  var unit_of_meas
  var value

  def init(name, value, dev_cla, unit_of_meas)
    self.name = name
    self.value = value
    self.dev_cla = dev_cla
    self.unit_of_meas = unit_of_meas
  end
end

#######################################################################
# Blerry_Binary_Sensor
#######################################################################
class Blerry_Binary_Sensor
  var name
  var dev_cla
  var unit_of_meas
  var value

  def init(name, value, dev_cla)
    self.name = name
    if value
      self.value = 'ON'
    else
      self.value = 'OFF'
    end
    self.dev_cla = dev_cla
  end
end

#######################################################################
# Blerry_Device
#######################################################################
class Blerry_Device
  var mac
  var config
  var b
  var alias
  var handle
  var active
  var attributes
  var sensors
  var sensors_to_discover
  var binary_sensors
  var binary_sensors_to_discover
  var topic
  var publish_available

  def init(mac, config, blerry_inst)
    self.mac = mac
    self.config = config
    self.b = blerry_inst
    self.alias = config['alias']
    self.load_driver()
    self.attributes = {}
    self.sensors = {}
    self.sensors_to_discover = []
    self.binary_sensors = {}
    self.binary_sensors_to_discover = []

    # static attributes
    self.add_attribute('MAC', self.mac)
    self.add_attribute('Alias', self.alias)
    self.add_attribute('Model', self.config['model'])

    # publication related
    self.publish_available = false
    self.topic = self.config['base_topic']
    if self.topic[-1] != '/'
      self.topic = self.topic + '/'
    end
    self.topic = self.topic + self.alias
  end

  def load_driver()
    var model_drivers = 
    {
      'dev'             : 'blerry_driver_dev.be',
      'ATCpvvx'         : 'blerry_driver_ATCpvvx.be',
      'ATC'             : 'blerry_driver_ATCpvvx.be',
      'pvvx'            : 'blerry_driver_ATCpvvx.be',
      'GVH5074'         : 'blerry_driver_GVH5074.be',
      'GVH5075'         : 'blerry_driver_GVH5075.be',
      'GVH5072'         : 'blerry_driver_GVH5075.be',
      'GVH5101'         : 'blerry_driver_GVH5075.be',
      'GVH5102'         : 'blerry_driver_GVH5075.be',
      'IBSTH1'          : 'blerry_driver_IBSTH2.be',
      'IBSTH2'          : 'blerry_driver_IBSTH2.be',
      'Xiaomi'          : 'blerry_driver_Xiaomi.be',
      'ATCmi'           : 'blerry_driver_Xiaomi.be',
      'Xiaomi_LYWSDCGQ' : 'blerry_driver_Xiaomi.be',
      'ThermoPro_TP59'  : 'blerry_driver_ThermoPro_TP59.be',
      # 'GVH5182'         : 'blerry_driver_GVH5182.be',
      # 'GVH5183'         : 'blerry_driver_GVH5183.be',
      # 'GVH5184'         : 'blerry_driver_GVH5184.be',
      # 'ATCmi'           : 'blerry_driver_ATCmi.be',
      # 'WoSensorTH'      : 'blerry_driver_WoSensorTH.be',
      # 'WoContact'       : 'blerry_driver_WoContact.be',
      # 'WoPresence'      : 'blerry_driver_WoPresence.be',
    }
    var fn = model_drivers[self.config['model']]    
    blerry_handle = def () print('BLY: Driver did not load properly') end
    blerry_active = false
    blerry_helpers.ensure_driver_exists(fn)
    load(fn)
    self.handle = blerry_handle
    self.active = blerry_active
  end

  def add_attribute(name, value)
    self.attributes[name] = Blerry_Attribute(name, value)
  end

  def add_sensor_no_pub(name, value, dev_cla, unit_of_meas)
    if !self.sensors.contains(name)
      self.sensors_to_discover.push(name)
    end
    self.sensors[name] = Blerry_Sensor(name, value, dev_cla, unit_of_meas)
  end

  def add_sensor(name, value, dev_cla, unit_of_meas)
    if !self.sensors.contains(name)
      self.sensors[name] = Blerry_Sensor(name, value, dev_cla, unit_of_meas)
      self.sensors_to_discover.push(name)
      self.publish_available = true
    elif self.sensors[name].value != value
      self.sensors[name] = Blerry_Sensor(name, value, dev_cla, unit_of_meas)
      self.publish_available = true
    end
  end

  def add_binary_sensor_no_pub(name, value, dev_cla)
    if !self.binary_sensors.contains(name)
      self.binary_sensors_to_discover.push(name)
    end
    self.binary_sensors[name] = Blerry_Binary_Sensor(name, value, dev_cla)
  end

  def add_binary_sensor(name, value, dev_cla)
    if !self.binary_sensors.contains(name)
      self.binary_sensors[name] = Blerry_Binary_Sensor(name, value, dev_cla)
      self.binary_sensors_to_discover.push(name)
      self.publish_available = true
    elif self.binary_sensors[name].value != value
      self.binary_sensors[name] = Blerry_Binary_Sensor(name, value, dev_cla)
      self.publish_available = true
    end
  end

  def publish()
    if self.publish_available
      var msg = {}
      for a:self.attributes
        msg[a.name] = a.value
      end
      for s:self.sensors
        msg[s.name] = s.value
      end
      for bs:self.binary_sensors
        msg[bs.name] = bs.value
      end
      if self.config['via_pubs']
        msg['Time_via_' + self.b.device_topic] = msg['Time']
        msg['RSSI_via_' + self.b.device_topic] = msg['RSSI']
      end

      # calibration
      if self.config.contains('calibration')       # if calibration is defined in the config
        for k:self.config['calibration'].keys()    # loop over sensors being calibrated
          if msg.contains(k)                       # if we have that sensor value to calibrate
            var c = self.config['calibration'][k]  # calibration has to be a list
            if isinstance(c, list)
              if size(c) == 1                      # size 1 = just a delta
                msg[k] = c[0] + msg[k]
              elif size(c) == 2
                msg[k] = c[0] + c[1]*msg[k]        # size 2 = delta and slope
              end
            end
          end
        end
      end

      # precision
      if self.config.contains('precision')       # if precision is defined in the config
        for k:self.config['precision'].keys()    # loop over sensors being rounded
          if msg.contains(k)                     # if we have that sensor value to round
            msg[k] = blerry_helpers.round(msg[k], self.config['precision'][k])
          end
        end
      end

      tasmota.publish(self.topic, json.dump(msg), self.config['sensor_retain'])
      if self.config['publish_attributes']
        for k:msg.keys()
          tasmota.publish(self.topic + '/' + k, string.format('%s', msg[k]), self.config['sensor_retain'])
        end
      end
      self.publish_available = false
    end
  end

  def publish_discovery()
    self.publish_sensor_discovery()
    self.publish_binary_sensor_discovery()
  end

  def get_discovery_packet_base() # Make each time so it can be GC'd. Don't save as a member of the class.
    var msg = {}

    # LWT Part
    if self.config['use_lwt']
      msg['avty_t'] = self.b.device_tele_topic + '/LWT'
      msg['pl_avail'] = 'Online'
      msg['pl_not_avail'] = 'Offline'
    else
      msg['avty'] = []
    end

    # Device Association Part
    msg['dev'] = {}
    msg['dev']['ids'] = [('blerry_' + self.alias)]
    msg['dev']['name'] = self.alias
    msg['dev']['mf'] = 'BLErry ' + blerry_version
    msg['dev']['mdl'] = self.config['model']
    msg['dev']['via_device'] = self.b.hostname

    # Topic Part
    msg['json_attr_t'] = self.topic
    msg['stat_t'] = self.topic

    return msg
  end

  def publish_sensor_discovery()
    var topic_fmt = 'homeassistant/sensor/blerry_' + self.alias + '/%s/config'
    if size(self.sensors_to_discover)
      var msg = self.get_discovery_packet_base()

      # sensor timeout
      msg['exp_aft'] = 600

      # the parts that are unique to each sensor
      for s:self.sensors_to_discover
        msg['name'] = self.alias + ' ' + self.sensors[s].name
        msg['uniq_id'] = 'blerry_' + self.alias + '_' + self.sensors[s].name
        msg['dev_cla'] = self.sensors[s].dev_cla
        msg['unit_of_meas'] = self.sensors[s].unit_of_meas
        msg['val_tpl'] = '{{ value_json.' + self.sensors[s].name + ' }}'

        # Here, I can implement an override from the config

        tasmota.publish(string.format(topic_fmt, s), json.dump(msg), self.config['discovery_retain'])
      end
      self.sensors_to_discover = []
    end
  end

  def publish_binary_sensor_discovery()
    var topic_fmt = 'homeassistant/binary_sensor/blerry_' + self.alias + '/%s/config'
    if size(self.binary_sensors_to_discover)
      var msg = self.get_discovery_packet_base()

      # sensor timeout
      msg['exp_aft'] = 600

      # the parts that are unique to each sensor
      for s:self.binary_sensors_to_discover
        msg['name'] = self.alias + ' ' + self.binary_sensors[s].name
        msg['uniq_id'] = 'blerry_' + self.alias + '_' + self.binary_sensors[s].name
        if self.binary_sensors[s].dev_cla != 'none'
          msg['dev_cla'] = self.binary_sensors[s].dev_cla
        end
        msg['val_tpl'] = '{{ value_json.' + self.binary_sensors[s].name + ' }}'

        # Here, I can implement an override from the config

        tasmota.publish(string.format(topic_fmt, s), json.dump(msg), self.config['discovery_retain'])
      end
      self.binary_sensors_to_discover = []
    end
  end
end

#######################################################################
# Class for Blerry Instance
#######################################################################
class Blerry
  # blerry config
  var default_config
  var user_config
  var device_config
  var devices
  var details_trigger

  # tasmota config
  var device_topic
  var cmnd_prefix
  var stat_prefix
  var tele_prefix
  var full_topic_f
  var hostname
  var device_tele_topic


  def init()
    self.get_tasmota_settings()
    self.load_default_config()
    self.load_user_config()
    self.setup_device_config()
    self.setup_devices()
    self.setup_packet_rule()
  end

  def get_tasmota_settings()
    self.device_topic = tasmota.cmd('Status')['Status']['Topic']
    self.cmnd_prefix = tasmota.cmd('Prefix1')['Prefix1']
    self.stat_prefix = tasmota.cmd('Prefix2')['Prefix2']
    self.tele_prefix = tasmota.cmd('Prefix3')['Prefix3']
    self.full_topic_f = tasmota.cmd('FullTopic')['FullTopic']
    self.hostname = tasmota.cmd('Status 5')['StatusNET']['Hostname']
    self.device_tele_topic = blerry_helpers.string_replace(blerry_helpers.string_replace(self.full_topic_f, '%prefix%', self.tele_prefix), '%topic%', self.device_topic)
    if self.device_tele_topic[-1] == '/' # allow / at the end but remove it here
      self.device_tele_topic = self.device_tele_topic[0..-2]
    end
  end

  # Load user config and default config from JSON files
  # Validate JSON with https://jsonformatter.curiousconcept.com/
  # Convert back and form to YAML with https://www.json2yaml.com/
  def load_user_config()  # based on persist module
    var f
    var val
    if path.exists("blerry_config.json")
      try
        f = open("blerry_config.json", "r")
        val = json.load(f.read())
        f.close()
      except .. as e, m
        if f != nil f.close() end
        raise e, m
      end
      if isinstance(val, map)
        self.user_config = val
      else
        raise "blerry_error", "failed to load blerry_config.json"
      end
    else
      raise "blerry_error", "no blerry_config.json found"
    end

    # sanitize mac addresses to be upper case
    var new_devices = {}
    for k:self.user_config['devices'].keys()
      var K = blerry_helpers.string_upper(k)
      new_devices[K] = self.user_config['devices'][k]
    end
    self.user_config['devices'] = new_devices

    self.details_trigger = 'DetailsBLE'
    if self.user_config.contains('advanced')
      if self.user_config['advanced'].contains('old_details')
        if self.user_config['advanced']['old_details']
          self.details_trigger = 'details'
        end
      end
    end
  end

  def load_default_config()
    self.default_config = 
    {
      'base_topic': 'tele/tasmota_blerry',
      'discovery': false,
      'discovery_retain': true,
      'use_lwt': false,
      'via_pubs': false,
      'sensor_retain': false,
      'publish_attributes': false,
      'ignored': false,
      'precision': 
      {
        'Temperature': 2,
        'DewPoint': 2,
        'Humidity': 1,
        'Battery': 0
      }
    }
  end

  # for each device: default, then device specific, then override, then ignore
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
      if self.user_config.contains('override')
        for k:self.user_config['override'].keys()
          self.device_config[m][k] = self.user_config['override'][k]
        end
      end
    end
    var ignored_devices = []
    for m:self.device_config.keys()
      if self.device_config[m]['ignored']
        ignored_devices.push(m)
      end
    end
    for m:ignored_devices
      self.device_config.remove(m)
    end
  end

  def setup_devices()
    var active = false
    self.devices = {}
    for m:self.device_config.keys()
      var device = Blerry_Device(m, self.device_config[m], self)
      
      # host based attributes here
      self.devices[m] = device
      active = active || device.active
      tasmota.cmd(string.format('BLEAlias %s=%s', device.mac, device.alias))
    end
    if active
      tasmota.cmd('BLEScan0 1')
    end
    tasmota.cmd('BLEDetails4')
  end

  def handle_BLE_packet(value, trigger, msg)
    var advert = BLE_AdvData(bytes(value['p']))
    try
      var device = self.devices[value['mac']]
      # device.handle(device, advert)
      var handle_f = device.handle
      handle_f(device, advert)
      device.add_attribute('Time', tasmota.time_str(tasmota.rtc()['local']))
      device.add_sensor_no_pub('RSSI', value['RSSI'], 'signal_strength', 'dB')
    except .. as e, m
      print('BLY: tried to handle mac =', value['mac'], 'with alias =', value['a'])
      raise e, m
    end
  end

  def setup_packet_rule()
    # tasmota.add_rule(self.details_trigger, def (value, trigger, msg) self.handle_BLE_packet(value, trigger, msg) end)
    tasmota.add_rule(self.details_trigger, / value, trigger, msg -> self.handle_BLE_packet(value, trigger, msg)) # "I prefer a lambda for the closure...." - sfromis
  end

  def publish()
    for d:self.devices
      d.publish()
    end
  end

  def publish_discovery()
    for d:self.devices
      d.publish_discovery()
    end
  end

  def load_success()
    print('BLY: BLErry ' + blerry_version + ' Loaded Successfully')
  end
end

#######################################################################
# Blerry_Driver
#   periodic publication of data
#   WebUI display of data
# The goal of using a driver for publication is to rate limit a bit
#######################################################################
class Blerry_Driver : Driver
  var b

  def init(blerry_inst)
    self.b = blerry_inst
  end

  def every_second()
    self.b.publish_discovery()
    self.b.publish()
  end

  def web_sensor()
    var msg = ""
    for d:self.b.devices
      msg = msg + "{s}<hr>{m}<hr>{e}"
      msg = msg + "{s}BLErry Device{m}<hr>{e}"
      if size(d.attributes)
        msg = msg + string.format("{s}-- Attributes --{m}<hr>{e}", d.alias)
        for a:d.attributes
          msg = msg + string.format("{s}%s{m}%s{e}", a.name, a.value)
        end
      end
      if size(d.sensors)
        msg = msg + string.format("{s}-- Sensors --{m}<hr>{e}", d.alias)
        for s:d.sensors
          msg = msg + string.format("{s}%s{m}%g %s{e}", s.name, s.value, s.unit_of_meas)
        end
      end
      if size(d.binary_sensors)
        msg = msg + string.format("{s}-- Binary Sensors --{m}<hr>{e}", d.alias)
        for bs:d.binary_sensors
          msg = msg + string.format("{s}%s{m}%s{e}", bs.name, bs.value)
        end
      end
    end
    msg = msg + "{s}<hr>{m}<hr>{e}"
    tasmota.web_send_decimal(msg)
  end
end

blerry = Blerry()
blerry_driver = Blerry_Driver(blerry)
tasmota.add_driver(blerry_driver)
tasmota.add_cmd("BlerrySetDevice", blerry_helpers.cmd_set_device)
tasmota.add_cmd("BlerryGetDevice", blerry_helpers.cmd_get_device)
tasmota.add_cmd("BlerryDelDevice", blerry_helpers.cmd_del_device)
tasmota.add_cmd("BlerryGetConfig", blerry_helpers.cmd_get_config)
tasmota.add_cmd("BlerrySetConfig", blerry_helpers.cmd_set_config)
tasmota.add_cmd("BlerryDelConfig", blerry_helpers.cmd_del_config)
blerry.load_success()
