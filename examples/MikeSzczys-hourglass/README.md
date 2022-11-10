# Wasting Time

A digital hourglass simulator for the 2022 Hackaday Superconference badge.

## Overview

This demo implements cellular automata to simulate sand in a hourglass. The app
loops through every row from the bottom to the top, testing each cell for the
existence of a grain of stand. When found the following rules are applied:

1. If the cell below is empty, the grain moves down
2. If the cell below and right is empty, the grain moves down and right
3. If the cell below and left is empty, the grain moved down and left
4. If none of the adjacent cells in the row below are empty, the grain is left
   in place

When every cell in the display is process, a loop counter is incremented. Every
three loops, a new grain of sand is created in the top row.

Once the origin location in the top row is occupied, the screen is considered
full. The memory will be cleared and the simulation starts anew.

## Video

Quick and dirty video demo:

https://www.youtube.com/watch?v=WmblmbdwMC8

## Resources

* [Badge for
  Supercon.6](https://hackaday.io/project/182568-badge-for-supercon6-november-20220)
  by Voja Antonic
* [2022 Hackaday Supercon 6 Badge Guide](https://hackaday.io/project/188025)
* [Assembly code tools for the Supercon.6 Badge](https://github.com/Hack-a-Day/2022-Supercon6-Badge-Tools/tree/main/assembler)
