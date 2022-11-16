# Windows badge flashing utility, submitted by ianjfrosst
import serial
import sys

# Set this to your serial adapter
PORT = 'COM0'

def load(fname):
    with open(fname, 'rb') as f:
        pgm = f.read()
    
    with serial.Serial(PORT) as s:
        s.write(pgm)
        s.flush()
        s.write(b'\0' * 1024) # sometimes flush doesn't seem to work. this'll fix it

if len(sys.argv) <= 1:
    print("Must provide .hex file to flash!")
    exit()

load(sys.argv[1])