# Symbol scroller

based on hamlet demo program by Voja Antonic

expanded chargen table to 6 bytes per character

removed automatic "space" column betweek character

ASCII assembler psuedo-op only accepts ASCII character. Hijacked a few
 characters we were not using. Improvement would add locations "after" the end
 of the ASCII string pseudo-op to allow extension of `chargen`

several "two character" symbols including:

* "~|": heart
* "{}": smile
* "\]\[": normal space invader (one empty column on each side)
* "^\": large space invader (no empty columns)
* "\_\`": small space invader (one empty start, two empty columns on end)
