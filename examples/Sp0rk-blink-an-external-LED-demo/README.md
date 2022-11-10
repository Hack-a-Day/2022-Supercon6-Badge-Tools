## Tiny demo - blink one or more LEDs wired to the expansion pins

I wrote these little programs in order to get going on reading the badge documentation so I could get started on doing things on the expansion board.   I figured these would be a jumpstart for others.

Hand entering the code with the clicky buttons is very satisfying but not necessary.   If you assemble the code on  the command line it will present you on standard output with the binary instructions that you can hand-enter as well as create a hex file for loading onto the badge.

So here's what to do.

1. Wire up an LED to the Out 0 pin on the positive side, ground on the negative side.   A resistor is good - value does not have to be precise.   If you are using one of those ubiquitous 5mm round dome lens throughhole LEDs, somewhere around 330 ohms is good.   Test it with 3v.   If it doesn't light, your resistor is too big.   If it smokes, your resistor is too small.    

Refer to the schematic and photographs.

3. Use one of the Blink1 programs to blink it

4. Then wire up 3 more LEDs and try the other programs.   Find the sections of the documentation that explain the instructions.

5. Try your own modifications

6. Input works similarly.


On linux:
* python3 <path to assemble.py> filename.asm   # to assemble into hex
* on badge: DIR mode then LOAD (not alt-load)
* connect with with UART
* stty -F /dev/ttyUSB0 9600 raw
* cat filename.hex > /dev/ttyUSB0 
* on badge: RUN mode then RUN

(use dmesg to validate that device is ttyUSB0 if necessary)
  
  
 
