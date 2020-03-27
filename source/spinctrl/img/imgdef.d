module spinctrl.img.imgdef;

import utils.misc;

import std.conv : to;

/// Number of LEDs in a group. **DO NOT CHANGE**
const ubyte GROUP_LEDS_COUNT = 4;
/// Number of groups of LEDs. safe to change, just be sure to put actual LEDs on spinner
const ubyte GROUP_COUNT = 5;
/// Length of image
const ubyte IMAGE_LEN = (2*GROUP_LEDS_COUNT*GROUP_COUNT) + 1;
/// Number of pixels in a square image of length 2xGROUP_COUNT*GROUP_LEDS_COUNT
const uint IMAGE_PIXELS_COUNT = IMAGE_LEN * IMAGE_LEN;

/// possible status of LEDs
package enum Color : ubyte{
	Off = 0B00000000, /// .
	Green = 0B00000001, /// .
	Blue = 0B00000010, /// .
	Cyan = 0B00000011, /// .
}

