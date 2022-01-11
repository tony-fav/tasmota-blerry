# Blerry - BLE Driver for Tasmota written in Berry

Requires a build with BLE and Berry (ESP32 devices only).

To use: 
- Upload `blerry.be`, `blerry_main.be`, and each `blerry_model_xxxx.be` model driver file you may need to the file system of the ESP32.
- Edit `blerry.be` as needed for your device configuration, HA discovery choices, etc... (make sure you delete the example configurations for devices you are not using).
- Create and enable (`Rule1 1`) the following Tasmota Rule and Restart Tasmota (Some of the commands used in `blerry.be` are not initialized by the time `autoexec.be` is run. So, you must load `blerry.be` as part of a rule.)
```
Rule1 ON System#Boot DO br load('blerry.be') ENDON
```

If you use HA discovery, devices should appear under MQTT Devices NOT the Tasmota integration.

## Troubleshooting

- Make sure BLE is enabled with `SetOption115 1`
- Ensure your rule with `ON System#Boot DO br load('blerry.be') ENDON` is enabled. If you used `Rule1` as described above, you enable it with `Rule1 1` in the console.
- Delete the example devices in `user_config`.
- Ensure your aliases are 20 characters or less (Tasmota default limit).
- Try your `user_config` definition in the Berry Scripting Console (Consoles -> Berry Scripting console). Look for extra or missing commas, extra or missing `'`, extra or missing `{` or `}`. Troubleshooting in the console will save a lot of time restarting Tasmota.
- Enable a higher weblog level when restarting (`Weblog 4` then `Restart 1`) to watch for errors during boot.
- Try loading Blerry just in the console with `br load('blerry.be')` and watch the logs for errors.
- Hop in the #blerry thread in the #tasmota channel of Digiblur's discord.

## Supported Sensors

| Model String   | Mac Example        | Description |
| -------------- | ------------------ | ----------- |
| `'ATCpvvx'`    | `'A4C138XXXXXX'`   | Xiaomi sensors on ATC or pvvx firmware with "ATC1441" or "Custom" advertisement. |
| `'ATCmi'`      | `'A4C138XXXXXX'`   | Xiaomi sensors on ATC or pvvx firmware with "Mi" advertisement. |
| `'GVH5075'`    | `'A4C138XXXXXX'`   | Govee H5072 and H5075. |
| `'GVH5182'`    | `'C33130XXXXXX/1'` | Govee H5182 two probe meat thermometer with display. Thanks carlthehaitian! |
| `'GVH5183'`    | `'A4C138XXXXXX'`   | Govee H5183 single probe meat thermometer. |
| `'GVH5184'`    | `'D03232XXXXXX/1'` | Govee H5184 four probe meat thermometer with display. Thanks ElksInNC! |
| `'IBSTH2'`     | `'494208XXXXXX'`   | Inkbird IBSTH1 & IBSTH2 with and without humidity. |
| `'WoSensorTH'` | `'D4E4A3XXXXXX/1'` | Switchbot temperature and humidity sensor. |
| `'WoContact'`  | `'D4BD28XXXXXX/1'` | Switchbot contact sensor (also has motion, binary lux, and a button). |
| `'WoPresence'` | `'FC7CADXXXXXX/1'` | Switchbot motion sensor (also has binary lux). |

## Development Status

I *have* the following devices that I am seeking to support:
- Switchbot Bot (this will be the first controllable device added to Blerry. I am still working on how I want to deal with it)
- Switchbot Curtain
- Switchbot Remote
- SP611E (LED Controller)
  
I *do not have* the following devices but would like to support them as they have been discussed in Digiblur's Discord.
- Govee H5074
- Some BBQ sensors

Feature Wish-List
- Sensor calibration, establish general method.
- Redo precision method to be consistent with a developed calibration method.
- A `blerry_model_dev.be` driver which spits out parsed, useful information to MQTT / a starting point for driver development.

## Intro Video by @digiblur (Thanks Travis!)

[![video thumbnail](http://img.youtube.com/vi/oJmDRkKnzFc/0.jpg)](http://www.youtube.com/watch?v=oJmDRkKnzFc "Tasmota ESP32 Bluetooth Blerry How To - Temperatures into Home Assistant")

## Contributing

Feel free to fork and PR any new drivers, better code, etc.!

I have added a document with some of the process for supporting the Govee H5183.

## If you like my project

<a href="https://www.buymeacoffee.com/tonyfav" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
