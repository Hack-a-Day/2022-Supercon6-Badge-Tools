#!/usr/bin/env python3

with open('hamlet_voja.hex', 'rb') as f:
    x = f.read()


header_x = x[:6]
checksum_x = x[-2:]
count_x = x[6:8]
message_x = x[8:-2]

with open("../hamlet.hex", 'rb') as f:
    y= f.read()

header_y = y[:6]
checksum_y = y[-2:]
count_y = y[6:8]
message_y = y[8:-2]

print(header_x,header_y)
print(checksum_x,checksum_y)
print(count_x, count_y)

i = 0
c = 0
myarray = count_y+message_y
while i<len(myarray):
    c += myarray[i] + (myarray[i+1]<<8)
    i += 2
print(hex(c&0xFFFF))
print("")

#for i in range(len(message_y)):
#    if message_y[i] != message_x[i]:
#        print("{:<5} || <{i, message_x[i], message_y[i])

for i in range(0,73,2):
    ln = 0 if i==0 else i/2
    print(int(ln),int(message_x[i]),int(message_x[i+1]))
