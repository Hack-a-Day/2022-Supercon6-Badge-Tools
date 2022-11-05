## Flashing firmware (Serial Bootloader Mode)

Instructions are in the manual, but here's the short version:

* If Linux, set your serial port to "raw" mode. `stty -F /dev/ttyUSB1 raw`

* Hold down ALT + LOAD and ground the Reset pin (far right on 12-pin header): should respond with slow blinking LOAD light

* Release buttons

* Start sending data, LOAD light blinks faster

* ~20-30 sec, both SAVE and LOAD lights on solid, denotes end

* Pressing MODE button gets you to a Version / Checksum display

* MODE again and you're done!

