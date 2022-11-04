TARGET:=bouncy_ball
PORT:=/dev/ttyUSB1
ASSEMBLER:=../../fbb_as.py

all: $(TARGET).hex flash

%.hex: %.asm
	$(ASSEMBLER) $^

flash: $(TARGET).hex
	stty -F $(PORT) raw
	cat $^ > $(PORT)


