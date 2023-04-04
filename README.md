# BLErry v0.2.3-dev - A BLE Gateway inside Tasmota32 using Berry

Here's an intro video by @digiblur to get an idea of the how and why! **HOWEVER, setup has changed, gotten simpler, since this video, see below.** Make sure to check out the discussions below.

[Contribute in Dev Branch](https://github.com/tony-fav/tasmota-blerry/tree/dev)

[Feature Requests](https://github.com/tony-fav/tasmota-blerry/discussions/27)

[Device Suggestions](https://github.com/tony-fav/tasmota-blerry/discussions/22)

[ESP32 Lock-Up/Reboot Issues](https://github.com/tony-fav/tasmota-blerry/discussions/28)

[![video thumbnail](http://img.youtube.com/vi/oJmDRkKnzFc/0.jpg)](http://www.youtube.com/watch?v=oJmDRkKnzFc "Tasmota ESP32 Bluetooth Blerry How To - Temperatures into Home Assistant")

## Setup

### Compatible ESP32

First, you must flash your ESP32 (or ESP32-C3 or ESP32-Solo1) with a Tasmota build with BLE and Berry. These are available from the [Tasmota Web Installer](https://tasmota.github.io/install/). The binaries are available here: [ESP32 Release](https://github.com/tasmota/install/blob/main/firmware/release/tasmota32-bluetooth.bin), [ESP32 Dev](https://github.com/tasmota/install/blob/main/firmware/development/tasmota32-bluetooth.bin), [ESP32-C3 Dev Only](https://github.com/tasmota/install/blob/main/firmware/unofficial/tasmota32c3-bluetooth.bin), and [ESP32-Solo1 Dev Only](https://github.com/tasmota/install/blob/main/firmware/unofficial/tasmota32solo1-bluetooth.bin). Additionally, this repo may from time to time host compiled Tasmota binaries that are confirmed to be stable for this project, provided there is any instability in the dev releases.

### Automated Setup

Provided your Tasmota32 device has internet access, BLErry can be installed automatically by running the following (`blerry_setup_script.be`) in the Berry Scripting Console (`http://your.tas.device.ip/bc?`)

```python
import path
def start_blerry_setup()
  var cl = webclient()
  var url = 'https://raw.githubusercontent.com/tony-fav/tasmota-blerry/dev/blerry/blerry_setup.be'
  cl.begin(url)
  var r = cl.GET()
  if r != 200
    print('error getting blerry_setup.be')
    return false
  end
  var s = cl.get_string()
  cl.close()
  var f = open('blerry_setup.be', 'w')
  f.write(s)
  f.close()
  load('blerry_setup.be')
end
start_blerry_setup()
```
This script will download a larger setup script and run it which downloads `blerry.be`, sets up a blank `blerry_config.json` if one does not already exist, sets up and enables a Rule to launch BLErry on Tasmota boot if one does not already exist, and restarts the ESP.

**If the script did not seem to work the first time. Run it again! There is some instability in downloading files to the ESP.**

Alternately, this setup script can be executed as a Tasmota command:

```
br import path; def start_blerry_setup(); var cl = webclient(); var url = 'https://raw.githubusercontent.com/tony-fav/tasmota-blerry/dev/blerry/blerry_setup.be'; cl.begin(url); var r = cl.GET(); if r != 200; print('error getting blerry_setup.be'); return false; end; var s = cl.get_string(); cl.close(); var f = open('blerry_setup.be', 'w'); f.write(s); f.close(); load('blerry_setup.be'); end; start_blerry_setup()
```

***IF AFTER INSTALLATION, BLERRY DOES NOT APPEAR TO BE WORKING, AND TASMOTA COMMANDS ARE UNKNOWN, PLEASE FOLLOW THE MANUAL SETUP GUIDE BELOW***. The automatic installation can fail leaving a blerry.be of size 0 on the filesystem.

### Tasmota Commands

There are several available Tasmota commands which can be used to setup devices or get information about the current setup.

The list of commands is below

```
BlerrySetDevice <JSON of a single device>
BlerryGetDevice <mac of a single device>
BlerryDelDevice <mac of a single device>
BlerrySetConfig <Complete JSON>
BlerryGetConfig
BlerryDelConfig
BlerryConfigURL <URL of blerry_config.json>
```

For example,

`BlerrySetDevice {"E33281034C99":{"alias":"dev_GVH5074","model":"GVH5074"}}`

would add this device (if it did not exist) to the configuration or edit the device to have this configuration if it did not previously. The rest of the configuration would remain intact. After this command, for changes to take effect, the Tasmota device should be restarted.

`BlerryDelDevice E33281034C99`

would delete the device configuration with mac address `E33281034C99` leaving the remaining configuration intact.

`BlerryConfigURL https://raw.githubusercontent.com/username/blerry/main/blerry_config.json`

would rewrite the entire configuration file to be the file from the provided URL.  This will auto update at every boot.

`BlerrySetConfig {"devices":{"E33281034C99":{"alias":"dev_GVH5074","model":"GVH5074"}}}`

would rewrite the entire configuration file to be the provided JSON.

These commands work like regular Tasmota commands, available through the console, serial, MQTT, HTTP request, etc.


### Alternate to System#Boot Rule

If you would like a fully berry solution to loading BLErry. Add the following line to `autoexec.be`

```tasmota.add_rule('System#Boot', / -> tasmota.set_timer(10000, / -> load('blerry.be')))```

This works similar to the rule but with a 10s. This delay seems to be required for BLErry to load properly. This is *likely* due to slight timing differences between Berry's rule processing and Tasmota's rule processing. This delay is also useful if you are running something like Tasmota Device Manager which also asks the ESP32 to do quite a lot at system boot.

### Manual Setup

Next, to use:
- Upload `blerry.be` to the file system of the ESP32. (`http://your.tas.device.ip/ufsd?`)
- Create the following Tasmota Rule:
```
Rule1 ON System#Boot DO br load('blerry.be') ENDON
```
- Enable the rule:
```
Rule1 1
```

### Final Setup (required for both automated and manual)
- Edit `blerry_config.json` as needed for your device configuration, HA discovery choices, etc... (make sure you delete the example configurations for devices you are not using) and upload to the file system of the ESP32 (`http://your.tas.device.ip/ufsd?`).
- If BLErry can't find a driver file (either source or compiled) on the file system and has access to the Internet, it will attempt to automatically download the needed drivers based on your [configuration file](#configuration-json). If your device does not have access to the Internet, you will need to upload each `blerry_driver_xxxx.be` driver file you may need to the file system of the ESP32.
- Restart Tasmota for BLErry to start working.
- Cleanup (optional) - After your device is configured and working properly you can free wasted space in the file system by deleting `blerry.be` and all `blerry_driver_xxxx.be` files. Make sure not to touch any of the `*.bec` files as those are necessary for the proper operation of BLErry.

If you use HA discovery, devices should appear under MQTT Devices NOT the Tasmota integration.

### Configuration JSON

As most folks in the home automation world are incredibly familiar with yaml, I suggest writing your configuration in yaml then converting it to JSON with https://www.json2yaml.com/

An example minimum configuration for 1 sensor is shown below in yaml

```yaml
devices:
  A4C138FFFFFF:
    alias: example_ATCpvvx
    model: ATCpvvx
```

This becomes `blerry_config.json` when converted

```json
{
  "devices": {
    "A4C138FFFFFF": {
      "alias": "example_ATCpvvx",
      "model": "ATCpvvx"
    }
  }
}
```

Adding a second device is just as simple

```yaml
devices:
  A4C138AAAAAA:
    alias: example_ATCpvvx
    model: ATCpvvx
  E33281BBBBBB:
    alias: another_sensor
    model: GVH5074
```

Again, you would convert this to json and save as `blerry_config.json`

If you would like to use the same configuration across multiple ESP32 devices, you can use the same config file but ignore specific sensors.

```yaml
devices:
  A4C138AAAAAA:
    alias: example_ATCpvvx
    model: ATCpvvx
  E33281BBBBBB:
    alias: another_sensor
    model: GVH5074
    ignore: true
```

Other settings can be added which override the default behavior and configured behavior for each device

```yaml
devices:
  A4C138AAAAAA:
    alias: example_ATCpvvx
    model: ATCpvvx
    sensor_retain: true
    precision:
      Temperature: 1
      Humidity: 0
      DewPoint: 1
  E33281BBBBBB:
    name: Living Room Sensor # friendly name shown in Home Assistant etc, if not set alias is used (ie use the alias as the name)
    alias: blerry_BBBBBB # used for BLE alias and mqtt topic
    model: GVH5074
    via_pubs: true
    publish_attributes: true
    calibration:
      Temperature: [ 1 ]
      Humidity: [ 0, 1.1 ]
```

Similarly, an override section can be defined which overrides the settings of every sensor (even if you specific individual settings for that sensor).

```yaml
devices:
  A4C138AAAAAA:
    alias: example_ATCpvvx
    model: ATCpvvx
    sensor_retain: true
    precision:
      Temperature: 1
      Humidity: 0
      DewPoint: 1
  E33281BBBBBB:
    alias: another_sensor
    model: GVH5074
    via_pubs: true
    publish_attributes: true
    calibration:
      Temperature: [ 1 ]
      Humidity: [ 0, 1.1 ]
override:
  base_topic: tele/tasmota_blerry2
  discovery: true
  precision:
    Battery: -1
```

For devices like scales that timeout and turn off when not in use or thermometers that have low digit precision and might not update often, the discovery of those specific sensors should be overriden to have a longer `exp_aft` time (default is 10 minutes = 600 seconds). The example below uses the `discovery_override` option to change the expire after time to 36 hours and change the state class to a measurement.

```yaml
devices:
  5CCAD3XXXXXX:
    model: MyScale
    alias: MiScale2
    discovery_override:
      Weight:
        stat_cla: measurement
        exp_aft: 129600
      Impedance:
        stat_cla: measurement
        exp_aft: 129600
```

Final reminder, you must convert this yaml to json and save a `blerry_config.json` to use it.

## Troubleshooting

- Make sure BLE is enabled with `SetOption115 1`
- Ensure your rule with `ON System#Boot DO br load('blerry.be') ENDON` is enabled. If you used `Rule1` as described above, you enable it with `Rule1 1` in the console.
- Delete the example devices in `blerry_config.json`.
- Ensure your aliases are 20 characters or less (Tasmota default limit).
- Try your `blerry_config.json` definition in a JSON validator such as https://jsonformatter.curiousconcept.com/
- Enable a higher weblog level when restarting (`Weblog 4` then `Restart 1`) to watch for errors during boot.
- Try loading BLErry just in the console with `br load('blerry.be')` and watch the logs for errors.
- Hop in the #blerry thread in the #tasmota channel of Digiblur's discord.
- Add a rule which enables device restart on wifi disconnect such as `ON Wifi#Connected Do RuleTimer1 0 ENDON ON Wifi#Disconnected Do RuleTimer1 60 ENDON ON Rules#Timer=1 Do Restart 1 ENDON`
- Ensure blerry.be is not size 0 on the filesystem. If it is, please follow the manual setup.
- ESP32-C3 based devices like the [SwitchBot Plug Mini](https://us.switch-bot.com/collections/all/products/switchbot-plug-mini) and Bulb
  - Tasmota 11.x and [12.0.2.2 dev](https://github.com/tasmota/install/raw/0533fd275fad9f4f3bf8350a6afdb9c6176d6879/firmware/unofficial/tasmota32c3-bluetooth.bin) seem to be the most stable right now. Newer versions seem to cause crashing.
  - Try SO57 0; This seems to improve reliability some.

## Supported Devices in BLErry v0.2.3-dev

Please discuss any devices you would like supported [here](https://github.com/tony-fav/tasmota-blerry/discussions/22) as well as if you are working on supporting any device!

### Sensors

| Driver Name          | Mac Example        | Description |
| -------------------- | ------------------ | ----------- |
| `"ATCpvvx"`          | `"A4C138XXXXXX"`   | Xiaomi sensors on ATC or pvvx firmware with "ATC1441" or "Custom" advertisement. |
| `"GVH5074"`          | `"E33281XXXXXX"`   | Govee H5074. *Need H5051 packets to add support to this driver.* |
| `"GVH5075"`          | `"A4C138XXXXXX"`   | Govee H5072, H5075, H5101, and H5102. |
| `"GVH5182"`          | `"C33130XXXXXX/1"` | Govee H5182 two probe meat thermometer with display. Thanks carlthehaitian! |
| `"GVH5183"`          | `"A4C138XXXXXX"`   | Govee H5183 single probe meat thermometer. |
| `"GVH5184"`          | `"D03232XXXXXX/1"` | Govee H5184 four probe meat thermometer with display. Thanks ElksInNC! |
| `"iBBQ6"`            | `"F83002XXXXXX"`   | Inkbird IBT-6XS and potentially other 6 probe iBBQ devices |
| `"IBSTH2"`           | `"494208XXXXXX"`   | Inkbird IBSTH1 & IBSTH2 with and without humidity. |
| `"ThermoPro_TP59"`   | `"487E48XXXXXX"`   | ThermoPro TP59. |
| `"WoContact"`        | `"D4BD28XXXXXX/1"` | Switchbot contact sensor (also has motion, binary lux, and a button). |
| `"WoPresence"`       | `"FC7CADXXXXXX/1"` | Switchbot motion sensor (also has binary lux). |
| `"WoSensorTH"`       | `"D4E4A3XXXXXX/1"` | Switchbot temperature and humidity sensor (regular and plus). |
| `"BTHome"`           | `"AABBCCDDEEFF"`   | BTHome format. Currently supports thermometer like readings *Can be expanded to more sensors* |
| `"Xiaomi"`           | `"AABBCCDDEEFF"`   | ATC/PVVX sensor on Mi-Like Advertising, Xiaomi LYWSDCGQ, Mi-Flora. *Can be expanded to more sensors* |
| `"MiScale2"`         | `"AABBCCDDEEFF"`   | Xiaomi Mi Scale 2 *See configuration section for configuration recommendation* |
| `"EufyC1"`           | `"AABBCCDDEEFF"`   | Anker eufy C1 Scale *See configuration section for configuration recommendation* |
| `"dev"`              | `"AABBCCDDEEFF"`   | A driver for easy development that prints out received raw data. |
| -- POLLED DEVICES -- |                    | Devices which require a BLEOp command to receive a Notification with data.|
| `WP6003`             | `"600303AABBCC"`   | WP6003 Air Box. |
## Development Status

I *have* the following devices that I am seeking to support which all require some control:
- Switchbot Bot
- Switchbot Curtain
- Switchbot Remote
- SP611E (LED Controller)
- MiPow Playbulb Candle (BTL300)

# Contributing

Feel free to fork and PR any new drivers, better code, etc.!

I have added a document with some of the process for supporting the Govee H5183 in v0.1.x. The implementation has changed drastically (to be easier) in v0.2.x.
## Drivers to Reference

- `ATCpvvx` driver shows how different BLE Advertisement Elements can be processed in the same driver file.
- `Xiaomi` shows how different information can be handled based on differing flags in a BLE Advertisement Element.
- `WoContact` has a button which shows how to immediately force MQTT publications to say 'ON' then right away 'OFF'.
- `WoContact` shows how to recall information from a device attribute if needed for later processing (button is a press counter).

# If you like my project

<a href="https://www.buymeacoffee.com/tonyfav" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
