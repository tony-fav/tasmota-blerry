# BLErry v0.2.x - A BLE Gateway inside Tasmota32 using Berry

Here's an intro video by @digiblur to get an idea of the how and why! HOWEVER, setup has changed, gotten simpler, since this video, see below. 

[![video thumbnail](http://img.youtube.com/vi/oJmDRkKnzFc/0.jpg)](http://www.youtube.com/watch?v=oJmDRkKnzFc "Tasmota ESP32 Bluetooth Blerry How To - Temperatures into Home Assistant")

## Basic Setup

First, you must flash your ESP32 (or ESP32-C3 or ESP32-Solo1) with a Tasmota build with BLE and Berry. These are available from the [Tasmota Web Installer](https://tasmota.github.io/install/). The binaries are available here: [ESP32 Release](https://github.com/tasmota/install/blob/main/firmware/release/tasmota32-bluetooth.bin), [ESP32 Dev](https://github.com/tasmota/install/blob/main/firmware/development/tasmota32-bluetooth.bin), [ESP32-C3 Dev Only](https://github.com/tasmota/install/blob/main/firmware/unofficial/tasmota32c3-bluetooth.bin), and [ESP32-Solo1 Dev Only](https://github.com/tasmota/install/blob/main/firmware/unofficial/tasmota32solo1-bluetooth.bin). Additionally, this repo may from time to time host compiled Tasmota binaries that are confirmed to be stable for this project, provided there is any instability in the dev releases.

Next, to use: 
- Upload `blerry.be` and each `blerry_driver_xxxx.be` driver file you may need to the file system of the ESP32. (`http://your.tas.device.ip/ufsd?`)
- Edit `blerry_config.json` as needed for your device configuration, HA discovery choices, etc... (make sure you delete the example configurations for devices you are not using) and upload to the file system of the ESP32.
- Create and enable (`Rule1 1`) the following Tasmota Rule and Restart Tasmota.
```
Rule1 ON System#Boot DO br load('blerry.be') ENDON
```

If you use HA discovery, devices should appear under MQTT Devices NOT the Tasmota integration.

## Configuration JSON

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
    alias: another_sensor
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

## Supported Sensors in BLErry v0.2.x

| Driver Name         | Mac Example        | Description |
| ------------------- | ------------------ | ----------- |
| `"ATCpvvx"`         | `"A4C138XXXXXX"`   | Xiaomi sensors on ATC or pvvx firmware with "ATC1441" or "Custom" advertisement. |
| `"GVH5074"`         | `"E33281XXXXXX"`   | Govee H5074. *Need H5051 packets to add support to this driver.* |
| `"GVH5075"`         | `"A4C138XXXXXX"`   | Govee H5072, H5075, H5101, and H5102. |
| `"IBSTH2"`          | `"494208XXXXXX"`   | Inkbird IBSTH1 & IBSTH2 with and without humidity. |
| `"ThermoPro_TP59"`  | `"487E48XXXXXX"`   | ThermoPro TP59. |
| `"Xiaomi"` | `"AABBCCDDEEFF"`   | Supports: ATC/PVVX sensor on Mi-Like Advertising and Xiaomi LYWSDCGQ. *Can be expanded to more sensors* |
| `"dev"`             | `"AABBCCDDEEFF"`   | A driver for easy development that prints out received raw data. |


## Sensors Supported in BLErry v0.1.x Remaning to Port

| Driver Name    | Mac Example        | Description |
| -------------- | ------------------ | ----------- |
| `"GVH5182"`    | `"C33130XXXXXX/1"` | Govee H5182 two probe meat thermometer with display. Thanks carlthehaitian! |
| `"GVH5183"`    | `"A4C138XXXXXX"`   | Govee H5183 single probe meat thermometer. |
| `"GVH5184"`    | `"D03232XXXXXX/1"` | Govee H5184 four probe meat thermometer with display. Thanks ElksInNC! |
| `"WoSensorTH"` | `"D4E4A3XXXXXX/1"` | Switchbot temperature and humidity sensor. |
| `"WoContact"`  | `"D4BD28XXXXXX/1"` | Switchbot contact sensor (also has motion, binary lux, and a button). |
| `"WoPresence"` | `"FC7CADXXXXXX/1"` | Switchbot motion sensor (also has binary lux). |

## Development Status

I *have* the following devices that I am seeking to support which all require some control:
- Switchbot Bot
- Switchbot Curtain
- Switchbot Remote
- SP611E (LED Controller)
- MiPow Playbulb Candle (BTL300)

# Contributing

Feel free to fork and PR any new drivers, better code, etc.!

I have added a document with some of the process for supporting the Govee H5183.

# If you like my project

<a href="https://www.buymeacoffee.com/tonyfav" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
