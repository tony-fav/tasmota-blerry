import path
import json
import string
def blerry_pull_file(file_name, url)
  var cl = webclient()
  cl.begin(url)
  var r = cl.GET()
  if r != 200
    print('error')
  end
  var s = cl.get_string()
  cl.close()
  var f = open(file_name, 'w')
  f.write(s)
  f.close()
end
def blerry_make_blank_config()
  var f = open('blerry_config.json', 'w')
  f.write(json.dump({'devices':{}}))
  f.close()
end
def blerry_setup()
  blerry_pull_file('blerry.be', 'https://raw.githubusercontent.com/tony-fav/tasmota-blerry/dev-blerry2/blerry2/blerry.be')
  blerry_make_blank_config()
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
blerry_setup()
print("Blerry Setup Complete")
tasmota.cmd('Restart 1')
