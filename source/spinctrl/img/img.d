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
	/// Returns: number of sectors
	@property ubyte sectorCount(){
		return sectors;
	}
	/// Returns: number of groups of LEDs
	@property ubyte groupCount(){
		return n;
	}
	/// possible status of LEDs
	enum Color : ubyte{
		Off = 0B00000000, /// .
		Green = 0B00000001, /// .
		Blue = 0B00000010, /// .
		Cyan = 0B00000011, /// .
	}
	/// stores the raw image, this directly represents the stream generated at end
	ubyte[n][sectors] _imgData;
	/// postblit, makes sure all _imgData are separate
	this(this){
		_imgData = _imgData.dup;
	}
	/// Returns: status of LEDs at a sector.
	Color[n*GROUP_LEDS_COUNT] readSector(ubyte sector){
		Color[n * GROUP_LEDS_COUNT] r;
		const ubyte[n] groups = _imgData[sector];
		foreach(index, group; groups){
			const ubyte index4 = index * 4;
			foreach(i; 0 .. 4){
				r[index4+(3 - i)] = cast(Color)((group >>> (i*2)) % 4);
			}
		}
		return r;
	}
	/// Writes to a sector
	/// 
	/// Returns: true on success, false on fail (i.e sector invalid)
	bool writeSector(ubyte sector, Color[n*GROUP_LEDS_COUNT] ledStatus){
		if (sector >= sectors)
			return false;
		ubyte[n] sectorData;
		foreach(i; 0 .. n){
			
		}
		_imgData[sector] = sectorData;
		return true;
	}
}