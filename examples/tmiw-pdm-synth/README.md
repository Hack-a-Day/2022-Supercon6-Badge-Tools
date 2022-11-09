# Introduction

This is a simple-ish program that generates square and triangle waves. 
Each wave can be one of four frequencies, too!

# Required connections

This program outputs audio on output pins 1-3 (pin 0 is always 1 due to optimizations in the
PDM logic that use the Out register as part of calculations). Only one of those three pins
needs to be connected. This connection must go to a low-pass filter to produce usable analog
audio.

Additionally, the audio after applying the LPF will likely be at a level too low to use directly.
Thus, it's highly recommended to connect the output to a circuit using a chip such as the NJM2113
to amplify it to a level usable for speakers. An example of such a circuit is  
[here](https://faculty.weber.edu/fonbrown/ee3710/lab8.pdf). Connections from the G and V pins
can be used to power whatever amplification circuit is used, but such circuit must be capable
of operating at 2-3V.

# Usage

The '8' key (under Opcode) controls the type of wave to be generated (currently square and triangle).
Pressing the '7' key will toggle the output between four different frequencies.

# TODO for future

* Implement sine wave support
* Fix bug where keypresses no longer work after pushing the '8' key.
