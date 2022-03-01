import json
var fake_print_time = tasmota.millis(5000)
fake_packet_options = [
  #
  # Sequence 1 - P1 Inserted/No alarm, Temp 70F, Setpoint unavail, P2 Inserted / No Alarm, Temp 72F, Setpoint 126F 
  '0201060303518414FF363E5E01000101B501860898FFFF8708981450', 
  '0201060303518414FF363E5E01000101B501860898FFFF8708981450', 
  #
  # Sequence 2 - P3 Not inserted/No alarm, Temp unavail, Setpoint 120F, P4 Inserted / Alarm, Temp 72F, Setpoint 68F 
  '0201060303518414FF363E5E01000101B60200FFFF1324C6089807D0', 
  '0201060303518414FF363E5E01000101B60200FFFF1324C6089807D0', 
  #
  # Sequence 1 - P1 Inserted/No alarm, Temp 70F, Setpoint unavail, P2 Not Inserted / No Alarm, Temp unavail, Setpoint 126F 
  '0201060303518414FF363E5E01000101B601860834FFFF07FFFF1450', 
  '0201060303518414FF363E5E01000101B601860834FFFF07FFFF1450', 
  #
  # Sequence 2 - P3 Inserted/No alarm, Temp 72F, Setpoint 120F, P4 Not Inserted / No Alarm, Temp unavail, Setpoint 68F 
  '0201060303518414FF363E5E01000101B602800898132406FFFF07D0',
  '0201060303518414FF363E5E01000101B602800898132406FFFF07D0',
  ]

fake_ble = Driver()
fake_ble.every_second = def ()
  if tasmota.millis() > fake_print_time
    var msg = {'DetailsBLE': {}}
    msg['DetailsBLE']['mac'] = 'D03232363E5E/1'
    msg['DetailsBLE']['a'] = 'dev_GVH5184'
    msg['DetailsBLE']['RSSI'] = -1
    var idx = tasmota.millis() % size(fake_packet_options)
    msg['DetailsBLE']['p'] = fake_packet_options[idx]
    tasmota.publish_result(json.dump(msg), 'BLY')
    fake_print_time = tasmota.millis(5000)
  end
end
tasmota.add_driver(fake_ble)
