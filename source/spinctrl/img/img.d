module spinctrl.img.img;

import utils.misc;

import std.conv : to;

/// Number of LEDs in a group
const ubyte GROUP_LEDS_COUNT = 4;

/// To store a raw frame, uncompressed
/// 
/// `n` is the number of groups of LEDs available
/// `sectors` is the number of sectors in a frame
package struct RawFrame(ubyte n = 4, ubyte sectors = 90){
	/// stores the raw image
	ubyte[n][sectors] _imgData;
	/// postblit
	this(this){
		_imgData = _imgData.dup;
	}
	/// Returns: status of LEDs (true = on, false = off) at a sector.
	/// The returned array contains status of Blue LEDs on even numbered (and 0) indexes, and Green at odd 
	bool[n*GROUP_LEDS_COUNT] readSector(ubyte sector){
		bool[n * GROUP_LEDS_COUNT] r;
		const ubyte[n] groups = _imgData[sector];
		foreach(index, group; groups){
			const ubyte index8 = index * 8;
			foreach(i; 0 .. 8){
				r[index8+(7 - i)] = (group >> i) % 2 ? true : false;
			}
		}
		return r;
	}
}