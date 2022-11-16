TARGET:=falldown
PORT:=/dev/ttyUSB0
ASSEMBLER:=../../assembler/assemble.py

all: $(TARGET).hex

%.hex: %.asm
	$(ASSEMBLER) $^

flash: $(TARGET).hex
	stty -F $(PORT) raw 9600
	cat $^ > $(PORT)


