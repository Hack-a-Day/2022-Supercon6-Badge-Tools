TARGET:=life
PORT:=/dev/ttyUSB1
ASSEMBLER:=../../assembler/assemble.py

all: $(TARGET).hex flash

%.hex: %.asm
	$(ASSEMBLER) $^

flash: $(TARGET).hex
	stty -F $(PORT) raw
	cat $^ > $(PORT)
