TARGET:=snake
PORT:=/dev/ttyUSB1
ASSEMBLER:=../../assembler/assemble.py

all: $(TARGET).hex

%.hex: %.asm
	$(ASSEMBLER) $^

flash: $(TARGET).hex
	stty -F $(PORT) raw
	cat $^ > $(PORT)

clean:
	rm -f *.hex
