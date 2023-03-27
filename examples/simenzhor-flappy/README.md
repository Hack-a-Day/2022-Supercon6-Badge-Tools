# Flappy Bit
_Copyright (c) 2023 Simen E. Sørensen | [@simenzhor@mastodon.social](https://mastodon.social/@simenzhor)_

-------------------------
A Flappy Bird clone for the Supercon/Hackaday Berlin badge.

## Acknowledgements
- I have used some functions from Octavian Voicu's "General Purpose Library" in [octav-snake](../octav-snake/snake.asm). 
  -   Octav's original library is written for a game played in portrait mode, so I have modified some functions to work better in landscape mode.
  - I have kept Octav's original coordinate system, where x exists in the range 0-7 and y in the range 0-14. The coordinate system's origin is in the top left corner of the screen (assuming portrait mode) near the R0/PAGE+1 labels 

- I have used the registry definitions from Bradon Kanyid / Rattboi in [rattboi-falldown](../rattboi-falldown/falldown.asm).

- I have used the Makefile from Adam Chasen in [achasen-symbolscroll](../achasen-symbolscroll/Makefile)
# Building

To build the binary, run:
```
make assemble
```

To load onto the badge 
1. Verify that the port specified in the Makefile matches yours:

2. Run `make all`

# Gameplay

Fly past as many obstacles as possible. 
Flap your wings to gain altitude, or let gravity pull you down towards the ground - but avoid crashing with the floor, ceiling or the obstacles you zoom past! 
The difficulty increases as you pass by obstacles. 

# Keys

The LSB key in the OPERAND Y section makes the bird jump. It is labeled
  * 1/++++

After the game is over, press any key in the OPERAND Y section to restart the game.

# High Score in Hackaday Berlin-Mode
If you played the game live at Hackaday Berlin, you may know that the game became borderline impossible to play as wall number 15 spawned. I have spent a bit more time balancing the game now, so it should be more fun to play, but if you are up for an extra challenge: flash your badge with `hackadayberlin-mode.hex` which is the original hex-file I showcased at the event. 

The world-record in Hackaday Berlin-mode is 19 walls and is held by [@bleeptrack@vis.social](https://vis.social/@bleeptrack)! 

# High Score in Source Code-Mode
My personal best score in the version that is published here is 23 walls, but that should be possible to beat, so toot at [@simenzhor@mastodon.social](https://mastodon.social/@simenzhor) if you manage to beat either of the high scores :D