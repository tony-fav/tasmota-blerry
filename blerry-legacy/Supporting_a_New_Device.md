# Supporting a New Device

As an example, we will use the Govee H5183 meat thermometer that was recently 40% off down to $8 on Amazon (https://amzn.to/3t3hqRJ digiblur affiliate link).

## Github Review

I did some searching on github and found this project which already supports the device https://github.com/wcbonner/GoveeBTTempLogger The relevant code is here https://github.com/wcbonner/GoveeBTTempLogger/blob/f3b86a9171e5d711798f1bd8788dbaa9ebb34d48/goveebttemplogger.cpp#L356

```c++
		else if (data_len == 17) // GVH5183 (UUID) 5183 B5183011
		{
			// Govee Bluetooth Wireless Meat Thermometer, Digital Grill Thermometer with 1 Probe, 230ft Remote Temperature Monitor, Smart Kitchen Cooking Thermometer, Alert Notifications for BBQ, Oven, Smoker, Cakes
			// https://www.amazon.com/gp/product/B092ZTD96V
			// The probe measuring range is 0° to 300°C /32° to 572°F.
			// 5D A1 B4 01 00 01 01 E4 01 80 0708 13 24 00 00
			// 2  3  4  5  6  7  8  9  0  1  2 3  4  5  6  7
			// (Manu) 5DA1B401000101E40080 0064 1324 0000 (Temp) 1°C (Humidity) 0% (Battery) 0% (Other: 00)  (Other: 00)  (Other: 00)  (Other: 00)  (Other: 00)  (Other: C8) 
			// (Manu) 5DA1B401000101E40080 0A28 1324 0000 (Temp) 26°C (Humidity) 0% (Battery) 0% (Other: 00)  (Other: 00)  (Other: 00)  (Other: 00)  (Other: 00)  (Other: C0) 
			// (Manu) 0ED27501000101E40080 0708 1518 0000
			short iTemp = short(data[12]) << 8 | short(data[13]);
			Temperature = float(iTemp) / 100.0;
			iTemp = short(data[14]) << 8 | short(data[15]);
			TemperatureMax = float(iTemp) / 100.0; // This appears to be the alarm temperature.
			Humidity = 0;
			Battery = 0;
			Averages = 1;
			time(&Time);
			TemperatureMin = Temperature;
			rval = true;
		}
```

So, we are not going in completely blind but pretty close to it with how many features the device could possibly have besides screaming its temp into the void.

## Stock App

Next, I'll play with the stock app and see what all features that we'd like to try and support. Fortunately, the Govee Home app does not require creating an account for use.

Pairing by press and hold for 3 seconds on the button. Mine showed up as "H5183_E05B"

Features in the app
- Can tell if probe is plugged in or not
- Has a battery indicator
- Has a timer that can be set
- Has a set temperature that can be set
- Settings
    - Temperature Unit
    - Device Buzzer
    - Early Warning (App Only Feature)
    - Calibration
    - Sound alarm
    - Vibration alarm
  
Firmware version 1.03.25, Hardware version 1.01.01, Product model H5183

As this is an purpose built device (alert when a temp is met in food), we probably don't want to just passively monitor temperature, especially because the device itself has on-board indicators ("device buzzer", "sound alarm", "vibration alarm"). Of course, we'll start just trying to get temperature then figure out how the other settings work. It also isn't clear to me without actually grilling something up using the sensor what settings are for the app and what settings are for the device.

## Tasmota BLEDetails2

`BLEDetails2 A4C138DAE05B`

Passive: probe plugged in, unplugged it, replugged it
```
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-17,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-28,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-18,"p":"0303518302010511FFDAE05B01000101E4008F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-21,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-17,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4008F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-17,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-18,"p":"0303518302010511FFDAE05B01000101E4008F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-26,"p":"0303518302010511FFDAE05B01000101E4008F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-17,"p":"0303518302010511FFDAE05B01000101E4010FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-61,"p":"0303518302010511FFDAE05B01000101E4000FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-21,"p":"0303518302010511FFDAE05B01000101E4010FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-16,"p":"0303518302010511FFDAE05B01000101E4010FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-14,"p":"0303518302010511FFDAE05B01000101E4010FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-16,"p":"0303518302010511FFDAE05B01000101E4000FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-15,"p":"0303518302010511FFDAE05B01000101E4010FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-30,"p":"0303518302010511FFDAE05B01000101E4000FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-34,"p":"0303518302010511FFDAE05B01000101E4000FFFFFFFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4008F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-21,"p":"0303518302010511FFDAE05B01000101E4018F0898FFFF0000000000000000"}}
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-19,"p":"0303518302010511FFDAE05B01000101E4008F0898FFFF0000000000000000"}}
```

Plugged in
```
03 03 5183
02 01 05
11 FF DAE05B01000101E4018F0898FFFF0000
extra 00s
```

Unplugged
```
03 03 5183
02 0105
11 FF DAE05B01000101E4000FFFFFFFFF0000
extra 00s
```

set temp at like 158
```
03 03 5183 
02 01 05 
11 FF DAE05B01000101E4018608983DB80000
extra 00s
```

changed a bunch of settings
```
03 03 5183
02 01 05
11 FF DAE05B01000101E4018608FC3DB8FF5A
extra 00s
```

```
DAE05B01 000101E4 018F 0898 FFFF 0000 plugged 22C
DAE05B01 000101E4 000F FFFF FFFF 0000 unplugged
DAE05B01 000101E4 0186 0898 3DB8 0000 with a set temp of 158C
DAE05B01 000101E4 0186 08FC 3DB8 FF5A -3F calibration
--------
mac
         -------- 
         haven't seen change
                  ----
                  changes randomnly?
                      ----
                      temp in C*100
                           ----
                           set temp in C*100
                                ----
                                calibration in C*100
```


Active Scan
```
{"DetailsBLE":{"mac":"A4C138DAE05B","RSSI":-20,"p":"0303518302010511FFDAE05B01000101E4008F0BB8FFFF00000000000000001AFF4C000215494E54454C4C495F524F434B535F48575075F2FF0C"}}
```

```
03 03 5183
02 01 05
11 FF DAE05B01000101E4008F0BB8FFFF0000
00
00
00
00
00
00
1A FF 4C000215494E54454C4C495F524F434B535F48575075F2FF0C
```

# Initial Setup for Testing

First, I make a new `blerry.be` with only one item in `user_config` and I assign the name I want to use for the device

```python
var user_config = {'A4C138DAE05B': {'alias': 'dev_GoveeH5183', 'model': 'GVH5183'}}
var base_topic = 'dev/log' # where to publish the sensor data
```

Next, I add the driver file to the `blerry_main.be` (to the map at line 110)

```python
# Load model handle functions only if used
var model_drivers = {'GVH5075'   : 'blerry_model_GVH5075.be',
                     'GVH5183'   : 'blerry_model_GVH5183.be',
                     'ATCpvvx'   : 'blerry_model_ATCpvvx.be',
                     'ATC'       : 'blerry_model_ATCpvvx.be',
                     'pvvx'      : 'blerry_model_ATCpvvx.be',
                     'ATCmi'     : 'blerry_model_ATCmi.be',
                     'IBSTH1'    : 'blerry_model_IBSTH2.be',
                     'IBSTH2'    : 'blerry_model_IBSTH2.be',
                     'WoSensorTH': 'blerry_model_WoSensorTH.be',
                     'WoContact' : 'blerry_model_WoContact.be',
                     'WoPresence': 'blerry_model_WoPresence.be'}
```

Next, I make the driver file `blerry_model_GVH5183.be` It starts small. In this case, I'm just seeing if I print out the right values for the 3 parameters I've identified.

```python
def handle_GVH5183(value, trigger, msg)
  if trigger == details_trigger
    var this_device = device_config[value['mac']]
    var p = bytes(value['p'])
    var i = 0
    var adv_len = 0
    var adv_data = bytes('')
    var adv_type = 0
    while i < size(p)
      adv_len = p.get(i,1)
      adv_type = p.get(i+1,1)
      adv_data = p[i+2..i+adv_len]
      if (adv_type == 0xFF) && (adv_len == 0x11)
          var this_data = [adv_data.get(10, -2), adv_data.get(12, -2), adv_data.geti(14, -2)]
          print(this_data)
      end
      i = i + adv_len + 1
    end
  end
end
  
# map function into handles array
device_handles['GVH5183'] = handle_GVH5183
require_active['GVH5183'] = false
```

After deploying this dev version of Blerry to a device I get output like this:
```
06:37:33.710 RSL: BLE = {"DetailsBLE":{"mac":"A4C138DAE05B","a":"dev_GoveeH5183","RSSI":-21,"p":"0303518302010511FFDAE05B01000101E4018608983DB8FF5A000000000000"}}
06:37:33.729 [2200, 15800, -166]
```

So, now it's time to essentially copy paste the rest of the driver in from other drivers. First, we make sure that we don't do any work if the new data is the same as the last data. Then discovery packets, then building the output map, then publishing the output map.

```python
def handle_GVH5183(value, trigger, msg)
  if trigger == details_trigger
    var this_device = device_config[value['mac']]
    var p = bytes(value['p'])
    var i = 0
    var adv_len = 0
    var adv_data = bytes('')
    var adv_type = 0
    while i < size(p)
      adv_len = p.get(i,1)
      adv_type = p.get(i+1,1)
      adv_data = p[i+2..i+adv_len]
      if (adv_type == 0xFF) && (adv_len == 0x11)
          var this_data = [adv_data.get(10, -2), adv_data.get(12, -2), adv_data.geti(14, -2)]
          var last_data = this_device['last_p']
          if (last_data != bytes('')) && (this_data == last_data)
            return 0
          end
          device_config[value['mac']]['last_p'] = this_data
          if this_device['discovery'] && !this_device['done_disc']
            publish_sensor_discovery(value['mac'], 'Temperature', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_Target', 'temperature', '°C')
            publish_sensor_discovery(value['mac'], 'Temperature_Calibration_C', 'temperature', 'ΔC')
            publish_sensor_discovery(value['mac'], 'Temperature_Calibration_F', 'temperature', 'ΔF')
            publish_binary_sensor_discovery(value['mac'], 'Probe_Status', 'connectivity')
            publish_sensor_discovery(value['mac'], 'RSSI', 'signal_strength', 'dB')
            device_config[value['mac']]['done_disc'] = true
          end
          var output_map = {}
          output_map['Time'] = tasmota.time_str(tasmota.rtc()['local'])
          output_map['alias'] = this_device['alias']
          output_map['mac'] = value['mac']
          output_map['via_device'] = device_topic
          output_map['RSSI'] = value['RSSI']
          if this_device['via_pubs']
            output_map['Time_via_' + device_topic] = output_map['Time']
            output_map['RSSI_via_' + device_topic] = output_map['RSSI']
          end
          if this_data[0] == 65535
            output_map['Probe_Status'] = 'OFF'
          else
            output_map['Probe_Status'] = 'ON'
          end
          output_map['Temperature'] = round((this_data[0] + this_data[2])/100.0, this_device['temp_precision'])
          output_map['Temperature_Target'] = round(this_data[1]/100.0, this_device['temp_precision'])
          output_map['Temperature_Calibration_C'] = round(this_data[2]/100.0, this_device['temp_precision'])
          output_map['Temperature_Calibration_F'] = round(this_data[2]/100.0*1.8, this_device['temp_precision'])
          var this_topic = base_topic + '/' + this_device['alias']
          tasmota.publish(this_topic, json.dump(output_map), this_device['sensor_retain'])
          if this_device['publish_attributes']
            for output_key:output_map.keys()
              tasmota.publish(this_topic + '/' + output_key, string.format('%s', output_map[output_key]), this_device['sensor_retain'])
            end
          end
      end
      i = i + adv_len + 1
    end
  end
end
  
# map function into handles array
device_handles['GVH5183'] = handle_GVH5183
require_active['GVH5183'] = false
```

For our basic/initial support, this completes the driver. Some notes,
- How the `this_data` and `last_data` is handled has really ended up being device-unique.
- I added a binary sensor that says if the probe is connected or not.
- I use the temp_precision to round the results.
- I publish the calibration value as both C and F because Home Assistant converts degree C to degree F, and that is not appropriate for a delta in temperature.

# Further Investigation

## BLE App (like LightBlue or nRF Connect)

With the help of the Mac found in the device name "E05B" I found mine to be A4:C1:38:DA:E0:5B. Connecting with nRF Connect did not provide too much info just the UUIDs and their functions (read, write, notify) which will be useful when trying to send commands to thing later but not helpful in understanding the communication protocol.


## Android BLE Debug Data

After playing in the app and noting what actions, I took, with bluetooth logging enabled in developer tools, I then get a bug report over ADB which contains a log file that can be opened in Wireshark.

`adb bugreport > BUG_REPORT.txt`

then a zip file is produced which contains the log file `bluetooth_hci.log`