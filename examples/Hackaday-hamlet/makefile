TARGET = hamlet
PORT = /dev/ttyUSB0
CC = ../../fbb_as.py

all: assemble program

assemble: $(TARGET)

$(TARGET): $(CC) $(TARGET).asm
	$(CC) $(TARGET).asm

clean:
	rm -f $(TARGET).hex

program:
	stty -F $(PORT) raw
	cat $(TARGET).hex > $(PORT)
