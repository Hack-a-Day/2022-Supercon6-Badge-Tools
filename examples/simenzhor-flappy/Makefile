TARGET=flappy
PORT?=/dev/ttyUSB0
ASSEMBLER=../../assembler/assemble.py

all: assemble program

assemble: $(TARGET)

$(TARGET): $(ASSEMBLER) $(TARGET).asm
		   $(ASSEMBLER) $(TARGET).asm

clean:
	rm -f $(TARGET).hex

program:
	stty -F $(PORT) raw
	cat $(TARGET).hex > $(PORT)
