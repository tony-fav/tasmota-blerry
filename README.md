# Blerry - BLE Driver for Tasmota written in Berry

Requires a build with BLE and Berry (ESP32 devices only).

To use: 
- Upload `blerry.be`, `blerry_main.be`, and each `blerry_model_xxxx.be` model driver file you may need to the file system of the ESP32.
- Edit `blerry.be` as needed for your device configuration, HA discovery choices, etc...
- Create and enable (`Rule1 1`) the following Tasmota Rule and Restart Tasmota (Some of the commands used in `blerry.be` are not initialized by the time `autoexec.be` is run. So, you must load `blerry.be` as part of a rule.)
```
Rule1 ON System#Boot DO br load('blerry.be') ENDON
```

## Intro Video by @digiblur (Thanks Travis!)

[![video thumbnail](http://img.youtube.com/vi/oJmDRkKnzFc/0.jpg)](http://www.youtube.com/watch?v=oJmDRkKnzFc "Tasmota ESP32 Bluetooth Blerry How To - Temperatures into Home Assistant")

## Contributing

Feel free to fork and PR any new drivers, better code, etc.!

## If you like my project

<a href="https://www.buymeacoffee.com/tonyfav" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
