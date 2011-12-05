
# Wild Bunch
a thin Quartz Composer plug-in for rich OSC communication

### HOW TO INSTALL FROM A BINARY RELEASE
move WildBunch.plugin into ~/Library/Graphics/Quartz Composer Plug-Ins/

### HOW TO BUILD
- clone the repository and submodules `git clone --recursive git://github.com/pizthewiz/WildBunch.git`
- [MacRuby](http://www.macruby.org/) is used to automate versioning of builds based on the current git revision, install it
- load up the project in Xcode, select the WildBunch scheme and build

### GENERAL
- the host can be defined as an IP address, symbolic hostname, ZeroConf hostname or with a fully qualified domain
- the message address is a pattern that defines the routing intent for the message's receiver(s)
- a message can be constructed to send multiple arguments

### BENEFITS AND MOTIVATION
the Apple OSC sender only allows one to send an OSC message with a single paramater (save the float array). additionaly, it does not support all OSC data types; OSC 1.1 added an Impulse (bang) data type which simplifies triggering data flows and reduces the need to _creatively_ use the True and False or Integer types in attempt to simulate the same result.

### THANKS
- Dean McNamee for his great OSC implementation for node.js [omgosc](https://github.com/deanm/omgosc)
- Jonathan del Strother for his more full-featured [BBOSC](https://github.com/jdelStrother/BBOSC) QC plug-ins
- Ray Cutler for his conical OSC implementation in [VVOpenSource](http://code.google.com/p/vvopensource/)
- Mirek Rusin for inspiration and reference with his [CoreOSC](https://github.com/mirek/CoreOSC/) library
- The [AsyncSocket](http://code.google.com/p/cocoaasyncsocket/) crew for a convenient UDP socket wrapper
