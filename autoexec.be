def SystemBoot_callback(value, trigger, msg)
    load('blerry.be')
end
tasmota.add_rule("System#Boot", SystemBoot_callback)