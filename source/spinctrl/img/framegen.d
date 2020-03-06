module spinctrl.img.framegen;

import spinctrl.img.imgdef;

import utils.lists;
import utils.misc;

import arsd.png;
import arsd.color;

import std.math;

public alias Color = spinctrl.img.imgdef.Color;

/// To generate RawFrames from PNG images or draw directly to them
public class FrameMake{
private:
	ubyte _sectors; /// number of sectors
public:
	/// constructor
	this(ubyte sectors){
		_sectors = sectors;
	}
	~this(){

	}
}

/// Returns: [angle, led] for a pixel at (x, y). If out of range, returns [-1, -1]
int[2] getLedAngle(ubyte x, ubyte y){
	/// center lines
	immutable ubyte center = GROUP_COUNT*GROUP_LEDS_COUNT; // 20
	/// stores quadrant
	immutable ubyte quadrant = x < center ? (y <= center ? 2 : 3) : (y <= center ? 1 : 4);
	// x, y, and hypotenuse distance from origin
	immutable uint xDist = x == center ? 0 : abs(center - x);
	immutable uint yDist = y == center ? 0 : abs(center - y);
	immutable uint led = cast(immutable uint)round(sqrt(cast(float)(pow(xDist, 2) + pow(yDist, 2))));
	if (xDist + yDist == 0 || led > center || led == 0)
		return [-1, -1];
	// now calculate angle
	immutable float baseAngle = abs(atan2(cast(float)yDist, cast(float)xDist)) * (180 / PI);
	immutable uint angle = cast(uint)(quadrant == 1 ? baseAngle : quadrant == 2 ? 180 - baseAngle : 
		quadrant == 3 ? 180 + baseAngle : 360 - baseAngle);
	return [angle, led-1];
}
/// 
unittest{
	debug{
		TrueColorImage img = new TrueColorImage(41, 41);
		foreach (ubyte x; 0 .. 41){
			foreach (ubyte y; 0 .. 41){
				int[2] pos = getLedAngle(x, y);
				if (pos[0] == -1 && pos[1] == -1){
					img.setPixel(x, y, arsd.color.Color.red);
				}else{
					img.setPixel(x, y, arsd.color.Color.green);
				}
			}
		}
		writePng("spot.png", img);
	}
}