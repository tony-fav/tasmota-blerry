# Why?

Between releases, Tasmota and Berry are in constant flux. I am not able to constantly update and test Blerry on each release. There's been many reports of crashing ESP32s,and it's basically impossible for me to support with how many different versions of Tasmota firmware are out there. 

So, I'm posting a few firmware files compiled against the exact build my "production" devices are running.

I have built it for regular ESP32, ESP32-C3, and ESP32 Single Cores (solo1 binary). The solo1 binary includes the commits from @pcdiem to support the Linkind Dimmer but it can be used for other purposes without issue.

As always, these binaries come with no warranty or guarantee of any kind. If you don't trust downloading from here, I have uploaded the user_config_override.h and platformio_override.ini used to compile the binaries and they are compiled against https://github.com/tony-fav/Tasmota/tree/dev-linkind-dim