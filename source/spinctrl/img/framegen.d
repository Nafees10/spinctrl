module spinctrl.img.framegen;

import spinctrl.img.imgdef;

import utils.lists;
import utils.misc;

import arsd.png;
import arsd.color;

// NOTE: CPixel or cpixel or cpix refers to a "pixel" on the circular display

/// To generate RawFrames from PNG images or draw directly to them
public class FrameMake{

}

/// Used by FrameMake to do trigonometric calculations
private class TrigCalc{
private:
	/// stores x position of cpixels. Read as: _xpos[(sector*GROUP_LEDS_COUNT*GROUP_COUNT) + (cpix-GROUP_LEDS_COUNT*GROUPCOUNT)]
	ubyte[] _xpos;
	/// stores y position of cpixels. Read as: _ypos[(sector*GROUP_LEDS_COUNT*GROUP_COUNT) + (cpix-GROUP_LEDS_COUNT*GROUPCOUNT)]
	ubyte[] _ypos;

	/// stores number of sectors
	ubyte _sectors;

	/// calculates _xpos and _ypos
	void calculate(){

	}
public:
	/// constructor
	/// 
	/// generates values for xPos and yPos, prepares to "render" to display, so this might take some time to exit
	/// 
	/// `sectorsCount` is number of sectors
	this(ubyte sectorsCount){
		_sectors = sectorsCount;
		calculate();
	}
	/// Returns: [x, y] coordinates of a CPixel at a sector
	ubyte[2] getCPixelPosition(ubyte cPixel, ubyte sector){
		immutable uint index = (sector*GROUP_LEDS_COUNT*GROUP_COUNT) + (cPixel-GROUP_LEDS_COUNT*GROUP_COUNT);
		return [_xpos[index], _ypos[index]];
	}
	/// Returns: [sector, cPixel] coordinates of a x, y pixel
	ubyte[2] getPixelPosition(ubyte x, ubyte y){
		
	}
}