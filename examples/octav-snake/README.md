## Snake for Voja's 4-bit processor.

_Copyright (c) 2022 Octavian Voicu_

For some functions that may be easily reusable in other projects, see the
"General Purpose Library" section in `snake.asm`.

# Building

To build the binary:
```
make
```

To load onto the badge (change the port accordingly):
```
make flash -e PORT=/dev/ttuUSB1
```

Alternatively, you can run in the [nibbler](
https://github.com/voctav/voja4_nibbler) emulator.

# Gameplay

This is the classic game of Snake. Every piece of food increases score by one.
Difficulty increases after every 16 points. There are 8 difficulty levels with
increasing game speeds. To win the game you have to fill the entire screen,
which amounts to 125 points.

# Keys

Use the four keys in the operand y section (from left to right):
  * 8 - left
  * 4 - up
  * 2 - down
  * 1 - right

After the game is over, press any of the above keys to restart the game.
