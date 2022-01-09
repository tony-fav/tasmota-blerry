Working on the code for the 4-probe Govee driver.  NOTE - any code is intended as psuedo-code and is not syntax correct.

The full 'p' string that comes from BLE looks like this:

0201060303518414FF363E5D01000101E40106FFFFFFFF06FFFFFFFF

Breaking that down:

```
02 01 06 03 03
-- -- -- -- -- <- static - not useful at this time

               51 84
               -- -- <- model number
                     14 FF
                     -- -- <- separator bytes - all useful data comes after these two static bytes. 
                                                We will look for this and start counting bytes after that
```

Remaining string to be manipulated:

   36 3E 5D 01 00 01 01 E4 01 06 FF FF FF FF 06 FF FF FF FF

```
   1  2  3 (Byte Sequence)
   36 3E 5D
   -- -- -- <- Last 3 bytes of MAC ADDRESS

            4  5  6  7  8   
            01 00 01 01 E4
            -- -- -- -- -- <- static, unknown, not needed at this time

                           9
                           01
                           -- <- Sequence number.  Can be 01 or 02.  01 is Probe1&2.  02 is Probe3&4.

                              10  
                              06
                              -- <- Probe1/3 status.  06 is no probe.  86 is probe inserted.

                                 11 12  
                                 FF FF
                                 -- -- <- Probe1/3 temp.  FF FF if not inserted.  Big-endian 2-byte number.  See below.

                                       13 14  
                                       FF FF
                                       -- -- <- Probe1/3 set point for alarm. Same scheme as temp.

                                             15
                                             06
                                             -- <- Probe2/4 status. 06 is no probe.  86 is probe inserted.
                                             
                                                16 17  
                                                FF FF
                                                -- -- <- Probe2/4 temp.  Same scheme as Probe 1/3

                                                      18 19  
                                                      FF FF
                                                      -- -- <- Probe2/4 set point for alarm. Same scheme as temp.
```


Building on other driver files, the following approach will be used.

1) Iterate through the string and find 14 and FF.  Assign the remaing 19 bytes to a variable.

2) We need to check if anything is changed so we don't do needless updates.  So we will always need a last_value and current_value. If
they are the same we can end and not update anything.

3) Declare last_value = stored ['last_value']

4) Check to see if last_value is empty - which means we are on our first pass and need to create a placeholder

5) If last_value does not yet exist - declare "last_value" and assign negative values for later test.)
    Last value will be a date structure list with the following values stored in the list.  This is a list and not a map
    so these names are just for documentation.  It will be a list of 12 INT values.
```
      [ Probe1 Status,
        Probe1 Temp,
        Probe1 Setpoint,
        Probe2 Status,
        Probe2 Temp,
        Probe2 Setpoint
        Probe3 Status,
        Probe3 Temp,
        Probe3 Setpoint,
        Probe4 Status,
        Probe4 Temp,
        Probe4 Setpoint ]
```     

5) Now we need to see if the current 'p' value is carrying the values for Probe1/2 or Probe3/4.  Since we only get half the probes on any pass - we
  have to parse out the values and push them into our current_value list based on which sequence we are on.  Check for sequence.

```
   If .get(8,-1) == 1 then #This is BYTE9 which contains the sequence number)
      sequence_index=0
   else
      sequence_index=6
```

6) Now we can use sequence index as an offset.  This will allow us to reuse the same block of code regardless of which sequence we are on.
```
      current_value[sequence_index] = .get((9+sequence_index),-1)
      current_value[sequence_index+1] = .get((10+sequence_index),-2)
      current_value[sequence_index+2] = .get((12+sequence_index),-2)
      current_value[sequence_index+3] = .get((14+sequence_index),-1)
      current_value[sequence_index+4] = .get((15+sequence_index),-2)
      current_value[sequence_index+5] = .get((17+sequence_index),-2)
```

7) Now we can compare current_value to last_value.  Both contain a complete set of 12 discrete values.  If the same return 0.

8) If they are not the same we will need to publish the updated data.  At this point - it is unclear if there is any advantage or disadvantage of publishing
all 12 pieces of data.  If we do discovery on Probe1/2 and Probe3/4 separtely and publish values for each separately - then we would not have entities for 
Probe 3/4 if they are not plugged in.  TBD.
they 
