Example creation of BLE advertisement interpretation using Tasmota.

Requires a build with BLE and Berry (ESP32 devices only).

Some of the commands used in `blerry.be` are not initialized by the time `autoexec.be` is run. So, you must load `blerry.be` as part of a rule.

```
Rule1 ON System#Boot DO br load('blerry.be') ENDON
```