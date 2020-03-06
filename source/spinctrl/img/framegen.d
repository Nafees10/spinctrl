module spinctrl.img.framegen;

import spinctrl.img.imgdef;

import utils.lists;
import utils.misc;

import arsd.png;
import arsd.color;

import std.math : sin, cos, PI, abs;

public alias Color = spinctrl.img.imgdef.Color;

/// To generate RawFrames from PNG images or draw directly to them
public class FrameMake{
private:
	TrigCalc _calcu; /// used to find position of pixels
	ubyte _sectors; /// number of sectors
public:
	/// constructor
	this(ubyte sectors){
		_sectors = sectors;
		_calcu = new TrigCalc(_sectors);
	}
	~this(){
		.destroy(_calcu);
	}
}

import std.stdio;

/// Used by FrameMake to do trigonometric calculations
private class TrigCalc{
private:
	/// stores led number for a [x, y]. Read as: [(y*width) + x]
	ubyte[] _leds;
	/// stores sector number for a [x, y]. Read as: [(y*width) + x]
	ubyte[] _sectors;

	/// stores number of sectors
	ubyte _sectorsCount;

	/// calculates _xpos and _ypos
	void calculate(){
		_leds.length = _sectorsCount * GROUP_LEDS_COUNT * GROUP_COUNT;
		_sectors.length = _leds.length;
		// by default, set all to 255
		_leds[] = 255;
		_sectors[] = 255;
		static const ubyte[2][4] origins = [
			[GROUP_LEDS_COUNT*GROUP_COUNT,GROUP_LEDS_COUNT*GROUP_COUNT],
			[(GROUP_LEDS_COUNT*GROUP_COUNT)-1,GROUP_LEDS_COUNT*GROUP_COUNT],
			[(GROUP_LEDS_COUNT*GROUP_COUNT)-1,(GROUP_LEDS_COUNT*GROUP_COUNT)+1],
			[(GROUP_LEDS_COUNT*GROUP_COUNT)+1,(GROUP_LEDS_COUNT*GROUP_COUNT)+1],
		];
		foreach(sector; 0 .. _sectorsCount){
			foreach(led; 0 .. GROUP_LEDS_COUNT * GROUP_COUNT){
				immutable float abAngle = (360 / _sectorsCount) * sector;
				immutable ubyte quadrant = abAngle <= 90 ? 1 : abAngle <= 180 ? 2 : abAngle <= 270 ? 3 : 4;
				immutable float xDist = led * abs(cos(abAngle * (PI / 180)));
				immutable float yDist = led * abs(sin(abAngle * (PI / 180)));
				uint x, y;
				if (quadrant == 1){
					x = cast(uint)(origins[1][0] + xDist);
					y = cast(uint)(origins[1][1] - yDist);
				}else if (quadrant == 2){
					x = cast(uint)(origins[1][0] - xDist);
					y = cast(uint)(origins[1][1] - yDist);
				}else if (quadrant == 3){
					x = cast(uint)(origins[1][0] - xDist);
					y = cast(uint)(origins[1][1] + yDist);
				}else if (quadrant == 4){
					x = cast(uint)(origins[1][0] + xDist);
					y = cast(uint)(origins[1][1] + yDist);
				}
				if ((x < 2*GROUP_COUNT*GROUP_LEDS_COUNT) && (y < 2*GROUP_COUNT*GROUP_LEDS_COUNT)){
					immutable uint index = (y*GROUP_COUNT*GROUP_LEDS_COUNT) + x;
					_leds[index] = cast(ubyte)led;
					_sectors[index] = cast(ubyte)sector;
				}
			}
		}
	}
public:
	/// constructor
	/// 
	/// generates values for xPos and yPos, prepares to "render" to display, so this might take some time to exit
	/// 
	/// `sectorsCount` is number of sectors
	this(ubyte sectorsCount){
		_sectorsCount = sectorsCount;
		calculate();
	}
	/// Returns: [sector, led] coordinates of a x, y pixel
	ubyte[2] getPixelPosition(ubyte x, ubyte y){
		immutable uint index = (y*GROUP_COUNT*GROUP_LEDS_COUNT) + x;
		return [_sectors[index], _leds[index]];
	}
}
/// 
unittest{
	// output coordinates to stdio, to see blind spots
	TrigCalc calcu = new TrigCalc(60);
	import std.stdio : writeln;
	TrueColorImage img = new TrueColorImage(40, 40);
	foreach (ubyte x; 0 .. 2*GROUP_COUNT*GROUP_LEDS_COUNT){
		foreach (ubyte y; 0 .. 2*GROUP_COUNT*GROUP_LEDS_COUNT){
			ubyte[2] pos = calcu.getPixelPosition(x, y);
			if (pos[0] == 255 || pos[1] == 255){
				img.setPixel(x, y, arsd.color.Color.red);
			}else{
				img.setPixel(x, y, arsd.color.Color.green);
			}
		}
	}
	writePng("spot.png", img);
}