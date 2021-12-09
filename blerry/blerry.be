# --------- USER INPUT ---------
var user_config = {'A4C138AAAAAA': {'alias': 'trial_govee5075', 'model': 'GVH5075', 'discovery': true},
                   'A4C138BBBBBB': {'alias': 'other_govee5075', 'model': 'GVH5075', 'via_pubs': false},
                   'A4C138CCCCCC': {'alias': 'trial_ATCpvvx', 'model': 'ATCpvvx', 'discovery': true, 'use_lwt': true},
                   '494208DDDDDD': {'alias': 'trial_inkbird', 'model': 'IBSTH2', 'discovery': true}}
var base_topic = 'tele/tasmota_blerry'

# ------ ADVANCED  CONFIG ------
var old_details = false # Set to true if Tasmota build is before https://github.com/arendst/Tasmota/pull/13671 was merged
var override_config = {} # default_config is applied first, user_config is applied next to specific macs, then override_config overwrites anything entered.
                         # useful for if you wanted user_config the same on many devices except only send discovery on 1 device. have discovery off in user_config but add here.
# var override_config = {'temp_precision': 3,
#                        'humi_precision': 2}

# -------- LOAD  BLERRY --------
load('blerry_main.be') # Do not change this line