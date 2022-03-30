var ble = BLE()
var buf = bytes(-64)
var wp6003_notify_delta = 5*60*1000 # every 5 minutes
var wp6003_buffer_time = 5*1000 # 5 seconds

def time()
  return tasmota.time_str(tasmota.rtc()['local'])
end

def subscribe()
  print("CONN:", time(), "Subscribing...")
  ble.set_svc("fff0")
  ble.set_chr("fff4")
  ble.run(3)
end

def disconnect()
  print("DCON:", time(), "Disconnecting...")
  ble.run(5)
end

def cb(err, op, uuid)
  if op == 3
    if err == 0
      print("CALB:", time(), "Subscribed Successfully")
    else
      print("CALB:", time(), "Failed to Subscribe, Re-Trying in 1s")
      tasmota.set_timer(1000, subscribe)
    end
  elif op == 5 && err == 2
    print("CALB:", time(), "Disconnected Successfully")
    print('------------------------------------------')
  else
    print("CALB:", time(), err, op, uuid, buf)
  end
  
  if op == 103
    if buf[0..1] == bytes('120A')
      disconnect()
      tasmota.set_timer(wp6003_notify_delta - wp6003_buffer_time, subscribe)
    end
  end 
end
var cbp = tasmota.gen_cb(/e,o,u->cb(e,o,u))

ble.conn_cb(cbp, buf)
ble.set_MAC(bytes('60030394342A'), 0)

subscribe()
