
# Wild Bunch
a thin Quartz Composer plug-in for OSC communication

### GENERAL
- the host can be defined as an IP address, symbolic hostname, ZeroConf hostname or with a fully qualified domain
- the message address is a pattern defining the routing intent for the message's receiver(s)
- message construction supports multiple types and arguments

### BENEFITS AND MOTIVATION
the Apple OSC sender only allows one to send a single argument in an OSC message (save the float array). additionaly, it does not support all OSC data types,  OSC 1.1 added an Impulse (bang) data type which simplifies triggering flows and reduces the need to creatively use the True and False or Integer types in attempt to simulate the same need.
