# Utility to download programs from the badge, submitted by @koppanyh
# Instructions:
#   Go into DIR mode on your badge
#   Start this saver program
#   Press the SAVE button on your badge within 5 seconds of starting this program

import serial
import sys

# Specify the name of your output file, default to 'out.hex'
NAME = 'out.hex'
if len(sys.argv) > 1:
	NAME = sys.argv[1]

# Specify serial adapter COM port (check device manager for this)
PORT = 'COM0'

print('Ready for download...')
print('Please press SAVE on your badge.')

with open(NAME, 'wb') as f:
	with serial.Serial(port=PORT, baudrate=9600, timeout=5) as ser:
		count = 0
		while True:
			payload = ser.read()
			if payload:
				# print(hex(payload[0]))  # only here for debugging
				f.write(payload)
				count += len(payload)
			else:
				break
		print(f'Downloaded {count} bytes ({count - 8} bytes payload) to {NAME}')
