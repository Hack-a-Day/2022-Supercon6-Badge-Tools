# bvm.py
# Adam Zeloof
# 3.12.2022
# requires Python 3.10 or higher

import sys
from badge import Badge
import tkinter as tk
from PIL import Image, ImageTk
import csv

def get_bit(n, i):  
    """returns the i'th bit of the number n (in binary)"""
    if n & (1<<i):
        return 1
    else:
        return 0

class BVM:
    def __init__(self):
        self.badge = Badge()
        self.guiScale = 3
        self.width = 3696/self.guiScale
        self.height = 1992/self.guiScale
        self.window = tk.Tk()
        self.frameDelay = 10
        self.window.title("BVM: 2022 Hackaday Supercon.6 Badge Virtual Machine")
        self.canvas = tk.Canvas(self.window, width=self.width, height=self.height, bd=0)
        bg = Image.open("gui_assets/badgeface.jpg")
        bg.thumbnail((self.width, self.height), Image.ANTIALIAS)
        self.bgImage = ImageTk.PhotoImage(bg)
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.bgImage)
        self.canvas.pack()
        self.redLeds = []
        self.yellowLeds = []
        self.buttons = []
        self.parsePnp()
        self.redLeds.sort()
        self.yellowLeds.sort()
        self.canvas.pack()
        self.ledMap = {
            'page': [183, 156, 155, 154],
            'pc': [81,80,79,78, 89, 88, 87, 86, 85, 84, 83, 82],
            'clk': 148,
            'nclk': 149, 
            'opcode0': range(33,49),
            'opcode1': range(17,33),
            'opcode2': range(1,17)
        }

    def runtimeTasks(self):

        # Clock
        clock = self.badge.clock
        if clock == 1:
            self.redLeds[self.ledMap['clk']].setVal(1)
            self.redLeds[self.ledMap['nclk']].setVal(0)
        else:
            self.redLeds[self.ledMap['clk']].setVal(0)
            self.redLeds[self.ledMap['nclk']].setVal(1)

        # Page
        page = self.badge.page
        for i in range(0, 4):
            self.redLeds[self.ledMap['page'][i]-1].setVal(get_bit(page, i))
        # Stack pointer 182,181,180
        sp = self.badge.cpu.sp
        for i in range(0, 3):
            self.redLeds[181-i].setVal(get_bit(sp, i))




        # Program Counter
        pc = self.badge.cpu.getPC()
        for i in range(0, 12):
            self.yellowLeds[self.ledMap['pc'][i]-1].setVal(get_bit(pc, i))

        # Flags
        self.yellowLeds[74].setVal(self.badge.cpu.V)
        self.yellowLeds[75].setVal(self.badge.cpu.Z)
        self.yellowLeds[76].setVal(self.badge.cpu.C)

        # Memory matrix
        for i in range(0, 16):
            # PAGE
            data = self.badge.cpu.ram[i+16*page]
            for bit in range(0,4):
                self.redLeds[(i+1)*8-bit-1].setVal(get_bit(data, bit))
            # PAGE+1
            data = self.badge.cpu.ram[(i+16*((page+1)%16))]
            for bit in range(0,4):
                self.redLeds[(i+1)*8-bit-5].setVal(get_bit(data, bit))

        # Command Decoder
        # self.badge.opcode0
        opcode0 = self.badge.opcode0
        opcode1 = self.badge.opcode1
        opcode2 = self.badge.opcode2
        for bit in range(0,16):
            self.yellowLeds[self.ledMap["opcode0"][bit]-1].setVal(bit == opcode0)
            self.yellowLeds[self.ledMap["opcode1"][bit]-1].setVal(bit == opcode1)
            self.yellowLeds[self.ledMap["opcode2"][bit]-1].setVal(bit == opcode2)

        #self.badge.step()
        try:
            self.badge.update()
        except EOFError:
            return
        else:
            self.window.after(self.frameDelay, self.runtimeTasks)



    def load(self, file):
        if file is not None:
            self.badge.load(file)


    def run(self):
        self.window.after(self.frameDelay, self.runtimeTasks)
        self.window.mainloop()

    def parsePnp(self):
        # pcb width 174.955 mm    2701 px      15.44 px/mm    /2=7.72
        scale = 20.73/self.guiScale
        x0 = 13
        y0 = 4
        with open("gui_assets/pnp.csv", newline='') as csvfile:
            reader = csv.reader(csvfile)
            header = next(reader)
            for row in reader:
                if len(row) > 9:
                    elmId = row[0]
                    x = float(row[2][:-2])*scale+x0
                    y = self.height-(float(row[3][:-2])*scale+y0)
                    theta = float(row[9])
                    if elmId[0:2] == "LR":
                        num = int(elmId[3:])
                        self.redLeds += [LED(num, x, y, theta, "red", self.canvas,self.guiScale)]
                    elif elmId[0:2] == "LY":  
                        num = int(elmId[3:])
                        self.yellowLeds += [LED(num, x, y, theta, "yellow", self.canvas, self.guiScale)]
                    elif elmId[0:2] == "SW":
                        self.buttons += [Button(x, y, self.canvas, self.guiScale)]


class LED:
    def __init__(self, num, x, y, theta, color, canvas, scale):
        assert(color in ["red", "yellow"])
        self.x = x
        self.y = y
        self.scale = scale
        self.num = num
        self.theta = int(theta%360)
        #self.theta = -math.radians(theta)
        self.color = color
        prefix = self.color[0:3] + str(self.theta)
        if self.theta == 45:
            self.px = 60/self.scale
        else:
            self.px = 50/self.scale
        offImageObj = Image.open("gui_assets/leds/" + prefix + "off.jpg")
        offImageObj.thumbnail((self.px, self.px), Image.ANTIALIAS)
        onImageObj = Image.open("gui_assets/leds/" + prefix + "on.jpg")
        onImageObj.thumbnail((self.px, self.px), Image.ANTIALIAS)
        self.offImage = ImageTk.PhotoImage(offImageObj)
        self.onImage = ImageTk.PhotoImage(onImageObj)
        self.canvas = canvas
        self.val = 0
        self.draw()

    def __lt__(self, other):
        return self.num < other.num

    def __repr__(self):
        return str(self.num)

    def draw(self):
        self.image = self.canvas.create_image(self.x, self.y, anchor=tk.CENTER, image=self.offImage)

    def setVal(self, val):
        self.val = val
        if self.val:
            image = self.onImage
        else:
            image = self.offImage
        self.canvas.itemconfig(self.image, image=image)


##################### LED Map #####################
# Red LEDs:
# 1-128: Matrix (left-right, top-bottom)
# 129: ADDER 3 Cout
# 130: ADDER 3 Cin
# 131: ADDER 2 Cin
# 132: ADDER 1 Cin
# 133: ADDER 3 SUM
# 134: ADDER 2 SUM
# 135: ADDER 1 SUM
# 136: ADDER 0 SUM
# 137: ACC3 IN
# 138: ACC2 IN
# 139: ACC1 IN
# 140: ACC0 IN
# 141: ACC3 TMP
# 142: ACC2 TMP
# 143: ACC1 TMP
# 144: ACC0 TMP
# 145: ACC3 OUT
# 146: ACC2 OUT
# 147: ACC1 OUT
# 148: ACC0 OUT
# 149: CLK
# 150: nCLK
# 151: N (Next to EXR)
# 152: Carry Input Logic CIN (Cin ENA)
# 153: Carry Inpput Logic INV (DATA INV)
# 154: PG 3
# 155: PG 2
# 156: PG 1
# 157: MODE DIR
# 158: MODE SS
# 159: MODE RUN
# 160: MODE PGM
# 161: CARRY
# 162: SAVE
# 163: LOAD
# 164: CLOCK
# 165: OPCODE 8
# 166: OPCODE 4
# 167: OPCODE 2
# 168: OPCODE 1
# 169: OPERAND X 8
# 170: OPERAND X 4
# 171: OPERAND X 2
# 172: OPERAND X 1
# 173: OPERAND Y 8
# 174: OPERAND Y 4
# 175: OPERAND Y 2
# 176: OPERAND Y 1
# 177: DATA IN BIN
# 178: DATA IN SEL
# 179: ADDER 0 Cin
# 180: SP 2
# 181: SP 1
# 182: SP 0
# 183: PG 0
#
#
# Yellow LEDs:
# 1-16: OPERAND Y 0-15
# 17-32: OPERAND X 0-15
# 33-48: OPCODE 0-15
# 49: ADDER 0 DEST
# 50: ADDER 1 DEST
# 51: ADDER 2 DEST
# 52: ADDER 3 DEST
# 53: ADDER 0 SRC
# 54: ADDER 1 SRC
# 55: ADDER 2 SRC
# 56: ADDER 3 SRC
# 57: LOGIC 0 OR
# 58: LOGIC 1 OR
# 59: LOGIC 2 OR
# 60: LOGIC 3 OR
# 61: LOGIC 0 AND
# 62: LOGIC 1 AND
# 63: LOGIC 2 AND
# 64: LOGIC 3 AND
# 65: LOGIC 0 XOR
# 66: LOGIC 1 XOR
# 67: LOGIC 2 XOR
# 68: LOGIC 3 XOR
# 69: C IN
# 70: Z IN
# 71: V IN
# 72: V TMP
# 73: Z TMP
# 74: C TMP
# 75: V OUT
# 76: Z OUT
# 77: C OUT
# 78: PC 3
# 79: PC 2
# 80: PC 1
# 81: PC 0
# 82: PC 11
# 83: PC 10
# 84: PC 9
# 85: PC 8
# 86: PC 7
# 87: PC 6
# 88: PC 5
# 89: PC 4
###################################################

class Button:
    def __init__(self, x, y, canvas, scale):
        self.x = x
        self.y = y


if __name__ == "__main__":
    try:
        inFile = sys.argv[1]
    except IndexError:
        raise RuntimeError("Pass file name of the badge binary")
    bvm = BVM()
    bvm.load(inFile)
    bvm.run()
