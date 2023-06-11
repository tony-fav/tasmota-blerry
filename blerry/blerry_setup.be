import path
import json
import string
def blerry_pull_file(file_name, url)
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
def blerry_setup_config()
  if path.exists('blerry_config.json')
    print('Found an existing blerry_config.json')
  else
    var f = open('blerry_config.json', 'w')
    f.write(json.dump({'devices':{}}))
    f.close()
    print('Created a blank blerry_config.json')
  end
end
def blerry_remove_files()
  var driver_list = [
    'blerry_driver_dev.be',
    'blerry_driver_ATCpvvx.be',
    'blerry_driver_GVH5074.be',
    'blerry_driver_GVH5075.be',
    'blerry_driver_IBSTH2.be',
    'blerry_driver_Xiaomi.be',
    'blerry_driver_ThermoPro_TP59.be',
    'blerry_driver_WoContact.be',
    'blerry_driver_WoPresence.be',
    'blerry_driver_WoSensorTH.be',
    'blerry_driver_WoSensorTHO.be',
    'blerry_driver_GVH5182.be',
    'blerry_driver_GVH5183.be',
    'blerry_driver_GVH5184.be',
  ]
  for dn:driver_list
    if path.exists(dn)
      print('Removing driver file:', dn)
      path.remove(dn)
    end
    if path.exists(dn + 'c')
      print('Removing driver file:', dn + 'c')
      path.remove(dn + 'c')
    end
  end
  if path.exists('blerry.bec')
    print('Removing blerry.bec')
    path.remove('blerry.bec')
  end
end
def blerry_setup_process_rules()
  var r1 = tasmota.cmd('Rule1')['Rule1']
  var r2 = tasmota.cmd('Rule2')['Rule2']
  var r3 = tasmota.cmd('Rule3')['Rule3']
  if string.find(r1['Rules'], "br load('blerry.be')") >= 0
    print('Found Blerry Load as Part of Rule 1')
    return true
  end
  if string.find(r2['Rules'], "br load('blerry.be')") >= 0
    print('Found Blerry Load as Part of Rule 2')
    return true
  end
  if string.find(r3['Rules'], "br load('blerry.be')") >= 0
    print('Found Blerry Load as Part of Rule 3')
    return true
  end
  print('Did not find Blerry Load as part of any Rule')
  if size(r1['Rules']) == 0
    tasmota.cmd("Rule1 ON System#Boot DO br load('blerry.be') ENDON")
    tasmota.cmd("Rule1 1")
    print("Created and Enabled Blerry Load Rule in Rule1")
    return true
  end
  if size(r2['Rules']) == 0
    tasmota.cmd("Rule2 ON System#Boot DO br load('blerry.be') ENDON")
    tasmota.cmd("Rule2 1")
    print("Created and Enabled Blerry Load Rule in Rule2")
    return true
  end
  if size(r3['Rules']) == 0
    tasmota.cmd("Rule3 ON System#Boot DO br load('blerry.be') ENDON")
    tasmota.cmd("Rule3 1")
    print("Created and Enabled Blerry Load Rule in Rule3")
    return true
  end
end
def blerry_setup_check_BLE_on()
  if tasmota.cmd('SetOption115')['SetOption115'] != 'ON'
    print('BLY: BLE is not enabled, enabling now.')
    tasmota.cmd('SetOption115 ON')
  end
end
def blerry_setup()
  if blerry_pull_file('blerry.be', 'https://raw.githubusercontent.com/tony-fav/tasmota-blerry/dev/blerry/blerry.be')
    blerry_setup_config()
    blerry_remove_files()
    blerry_setup_process_rules()
    blerry_setup_check_BLE_on()
    print("Blerry Setup Complete")
    tasmota.cmd('Restart 1')
  else
    print("Failed to Download 'blerry.be'. Please run setup script again.")
  end
end
blerry_setup()
