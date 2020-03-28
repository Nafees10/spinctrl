module spinctrl.img.framegen;

import spinctrl.img.imgdef;

import utils.lists;
import utils.misc;

import arsd.png;
import arsd.color;

import std.math;

public alias Color = spinctrl.img.imgdef.Color;

/// To generate RawFrames from PNG images or draw directly to them
public struct FrameMake{
	/// stores angle+led for each pixel. Read as `_angleLed[(y * width)+x]`. [0] is angle, [1] is 
	int[2][IMAGE_PIXELS_COUNT] _angleLed;
	/// maps pixels onto _angleLed. Must be called before using any other function
	void map(){
		foreach (uint y; 0 .. IMAGE_LEN){
			foreach (uint x; 0 .. IMAGE_LEN){
				immutable index = (y*IMAGE_LEN) + x;
				_angleLed[index] = getLedAngle(cast(ubyte)x, cast(ubyte)y);
			}
		}
	}
}

/// calculaets [angle, led] for every pixel. Orders the result in ascending order by angle
/// 
/// Returns: [angle, led] for every pixel, sorted by angle (ascending)
private int[2][] getLedAngle(){
	int[2][IMAGE_PIXELS_COUNT] angleLeds;
	foreach (uint y; 0 .. IMAGE_LEN){
		foreach (uint x; 0 .. IMAGE_LEN){
			immutable index = (y*IMAGE_LEN) + x;
			angleLeds[index] = getLedAngle(cast(ubyte)x, cast(ubyte)y);
		}
	}
	int[] angles;
	angles.length = IMAGE_PIXELS_COUNT;
	foreach (i, angleLed; angleLeds){
		angles[i] = angleLed[0];
	} 
	immutable uinteger[] newIndexes = angles.sortAscendingIndex;
	int[2][IMAGE_PIXELS_COUNT] orderedList;
	foreach (i, originalIndex; newIndexes){
		orderedList[i] = angleLeds[originalIndex];
	}
	uint discardCount = 0;
	foreach (i; 0 .. IMAGE_PIXELS_COUNT){
		if (orderedList[i][0] > -1)
			break;
		discardCount ++;
	}
	return orderedList[discardCount .. $].dup;
}
///
unittest{
	import std.conv : to;
	int[2][] list = getLedAngle;
	string[] strList;
	strList.length = list.length;
	foreach (i, val; list){
		strList[i] = list[i][0].to!string ~ "\t\t" ~list[i][1].to!string;
	}
	strList = "angle\tled" ~ strList;
	arrayToFile(strList, "angles");
}

/// Returns: [angle, led] for a pixel at (x, y). If out of range, returns [-1, -1]
private int[2] getLedAngle(uint x, uint y){
	/// center lines
	immutable uint center = GROUP_COUNT*GROUP_LEDS_COUNT; // 20
	/// stores quadrant
	immutable ubyte quadrant = x < center ? (y <= center ? 2 : 3) : (y <= center ? 1 : 4);
	// x, y, and hypotenuse distance from origin
	immutable uint xDist = x == center ? 0 : abs(cast(int)center - cast(int)x);
	immutable uint yDist = y == center ? 0 : abs(cast(int)center - cast(int)y);
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
	TrueColorImage img = new TrueColorImage(IMAGE_LEN, IMAGE_LEN);
	foreach (ubyte x; 0 .. IMAGE_LEN){
		foreach (ubyte y; 0 .. IMAGE_LEN){
			int[2] pos = getLedAngle(x, y);
			if (pos[0] == -1 || pos[1] == -1){
				img.setPixel(x, y, arsd.color.Color.red);
			}else{
				img.setPixel(x, y, arsd.color.Color.green);
			}
		}
	}
	writePng("spot.png", img);
}