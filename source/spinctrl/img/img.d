module spinctrl.img.img;

import utils.misc;

import std.conv : to;

/// Number of LEDs in a group
const ubyte GROUP_LEDS_COUNT = 4;

/// To store a raw frame, uncompressed
/// 
/// `n` is the number of groups of LEDs available
/// `sectors` is the number of sectors in a frame
package struct RawFrame(ubyte n = 5, ubyte sectors = 72){
	/// possible colors of LEDs
	enum Color : ubyte{
		Green, /// .
		Blue, /// .
	}
	/// stores the raw image
	ubyte[n][sectors] _imgData;
	/// postblit
	this(this){
		_imgData = _imgData.dup;
	}
	/// Returns: status of both color LEDs (true = on, false = off) at a sector.
	/// Green are even indexes (including zero), blue are odd
	bool[n*GROUP_LEDS_COUNT*2] readSector(ubyte sector){
		bool[n * GROUP_LEDS_COUNT*2] r;
		const ubyte[n] groups = _imgData[sector];
		foreach(index, group; groups){
			const ubyte index8 = index * 8;
			foreach(i; 0 .. 8){
				r[index8+(7 - i)] = (group >> i) % 2 ? true : false;
			}
		}
		return r;
	}
	/// Returns: status of 1 colored LEDs (true = on, false = off) at a sector
	bool[n*GROUP_LEDS_COUNT] readSector(ubyte sector, Color col){
		/// offset due to color choice
		const ubyte colorOffset = col == Color.Green ? 0 : 1;
		bool[n * GROUP_LEDS_COUNT] r;
		const ubyte[n] groups = _imgData[sector];
		foreach(index, group; groups){
			const ubyte index4 = index * 4;
			foreach(i; 0 .. 4){
				r[index4+7 - ((i*2)+colorOffset)] = (group >> (i*2)+colorOffset) % 2 ? true : false;
			}
		}
		return r;
	}

}