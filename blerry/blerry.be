# Settings are applied in the order: default_config to all MACs found in user_config
#                                    user_config to the individual MACs they map to
#                                    override_config to all MACs found in user_config
# This sequence gives the ability to use the same user_config on on multiple Tasmota devices
# but perhaps using override config to turn on HA discovery from one of the Tasmota devices
# or to temporarily enable via_pubs from one of the Tasmota devices to check RSSI without
# having to adjust user_config.


# --------- USER INPUT ---------
# user_config map (mac and config options pairs)
#   alias               REQUIRED                        name you are assigning the device
#   model               OPTIONAL (default = 'ATCpvvx')  BLE device model to associate with mac
#   discovery           OPTIONAL (default = false)      publish HA MQTT discovery payloads
#   use_lwt             OPTIONAL (default = false)      use LWT for availability in discovery payloads (discovery packet also include 600s timeout of sensor data)
#   via_pubs            OPTIONAL (default = false)      publish Time_via_%topic% and RSSI_via_%topic% data with each data set
#   sensor_retain       OPTIONAL (default = false)      add retain flag to sensor data set publishes
#   publish attributes  OPTIONAL (default = false)      publish individual topics for each attribute in addition to the JSON payload
#   temp_precision      OPTIONAL (default = 2, int)     digits of precision for temperature
#   humi_precision      OPTIONAL (default = 1, int)     digits of precision for humidity
var user_config = {'A4C138AAAAAA': {'alias': 'trial_govee5075', 'model': 'GVH5075', 'discovery': true},
                   'A4C138BBBBBB': {'alias': 'other_govee5075', 'model': 'GVH5075', 'via_pubs': false},
                   'A4C138XXXXXX': {'alias': 'govee5183meats', 'model': 'GVH5183'},
                   'D03232XXXXXX/1': {'alias': 'govee5184-4probe-meats', 'model': 'GVH5183'},
                   'A4C138CCCCCC': {'alias': 'trial_ATCpvvx', 'model': 'ATCpvvx', 'discovery': true, 'use_lwt': true},
                   'A4C138CCCCCC': {'alias': 'ATC_on_milike', 'model': 'ATCmi'},
                   '494208DDDDDD': {'alias': 'trial_inkbird', 'model': 'IBSTH2', 'discovery': true},
                   'D4E4A3BBBBBB/1': {'alias': 'sbot_TH', 'model': 'WoSensorTH'},
                   'D4BD28AAAAAA/1': {'alias': 'sbot_contact', 'model': 'WoContact'},
                   'FC7CADCCCCCC/1': {'alias': 'sbot_motion', 'model': 'WoPresence'}}
var base_topic = 'tele/tasmota_blerry' # where to publish the sensor data


# --- GLOBAL OVERRIDE CONFIG ---
# override_config map (only config options)
#   all options from user_config except alias
var override_config = {}
# var override_config = {'discovery': true}
# var override_config = {'temp_precision': 3,
#                        'humi_precision': 2}


# ----------- DEFAULT ----------
# default_config map (only config options)
#   all options from user_config except alias
# user should not have to edit this config except in extreme edge cases
var default_config = {'model': 'ATCpvvx',            # Must match 'ATCpvvx', 'GVH5075', or 'IBSTH2'
                      'discovery': false,            # HA MQTT Discovery
                      'use_lwt': false,              # use receiving device's LWT as LWT for BLE device
                      'via_pubs': false,             # publish attributes like "Time_via_%topic%" and "RSSI_via_%topic%" (default false to reduce workload on ESP)
                      'sensor_retain': false,        # retain publication of data
                      'publish_attributes': false,   # publish attributes to individual topics in addition to JSON payload (default false to reduce workload on ESP)
                      'temp_precision': 2,           # digits of precision for temperature
                      'humi_precision': 1}           # digits of precision for humidity


# ------ ADVANCED  CONFIG ------
var old_details = false # Set to true if Tasmota build is before https://github.com/arendst/Tasmota/pull/13671 was merged
var discovery_retain = true # only false when testing


# -------- LOAD  BLERRY --------
load('blerry_main.be') # Do not change this line
