#!/usr/bin/env python3

with open('../hamlet.s', 'r') as f:
    hamlet = f.read().split('\n')
with open('hamlet_voja.s', 'r') as f:
    hamlet_out = f.read().split('\n')

print("{:<5} || {:<50} || {:<50}".format("Line:","Voja's disassembly","This program's disassembly"))
for i,l in enumerate(hamlet):
    if l != hamlet_out[i]:
        print("{:<5} || {:<50} || {:<50}".format(i,hamlet_out[i],l))
