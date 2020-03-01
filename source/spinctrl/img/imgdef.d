module spinctrl.img.imgdef;

import utils.misc;

import std.conv : to;

/// Number of LEDs in a group. DO NOT CHANGE
const ubyte GROUP_LEDS_COUNT = 4;

/// possible status of LEDs
package enum Color : ubyte{
	Off = 0B00000000, /// .
	Green = 0B00000001, /// .
	Blue = 0B00000010, /// .
	Cyan = 0B00000011, /// .
}

/// To store a raw frame, uncompressed
/// 
/// `n` is the number of groups of LEDs available
/// `_imgData.length` is the number of _imgData.length in a frame
/// 
/// keep in mind that the _imgData.length are read from LED closest to circumference at index 0
package struct RawFrame(ubyte n = 5){
	/// constructor
	this (ubyte sectorsCount){
		this._imgData.length = sectorsCount;
	}
	/// Returns: number of sectors
	@property ubyte sectors(){
		return cast(ubyte)(_imgData.length);
	}
	/// Returns: number of groups of LEDs
	@property ubyte groupCount(){
		return n;
	}
	/// stores the raw image, this directly represents the stream generated at end
	ubyte[n][] _imgData;
	/// postblit, makes sure all _imgData are separate
	this(this){
		_imgData = _imgData.dup;
	}
	/// Returns: status of LEDs at a sector.
	Color[n*GROUP_LEDS_COUNT] readSector(ubyte sector){
		Color[n * GROUP_LEDS_COUNT] r;
		const ubyte[n] groups = _imgData[sector];
		foreach(index, group; groups){
			const ubyte index4 = cast(const ubyte)(index * 4);
			foreach(i; 0 .. 4){
				r[index4+i] = cast(Color)((group >>> (i*2)) % 4);
			}
		}
		return r;
	}
	/// Writes to a sector
	/// 
	/// Returns: true on success, false on fail (i.e sector invalid)
	bool writeSector(ubyte sector, Color[n*GROUP_LEDS_COUNT] ledStatus){
		if (sector >= _imgData.length)
			return false;
		foreach(group; 0 .. n){
			ubyte groupData;
			const ubyte readIndex = cast(const ubyte)(group*GROUP_LEDS_COUNT);
			foreach (i; 0 .. GROUP_LEDS_COUNT){
				groupData += ledStatus[readIndex + i] << (i*2);
			}
			_imgData[sector][group] = groupData;
		}
		return true;
	}
	/// Converts this frame into a single stream of ubytes
	/// 
	/// if `includeHeader` is true, the header will be put at start of stream. Format for header is:
	/// `[0x00, n(groups), n(_imgData.length)]`
	ubyte[] toStream(bool includeHeader = false){
		ubyte[] r = [];
		if (includeHeader){
			r = [0x00, n, cast(ubyte)(_imgData.length)];
		}
		// start appending _imgData.length to it
		uinteger writeIndex = r.length;
		r.length += _imgData.length * n;
		foreach (sector; _imgData){
			r[writeIndex .. writeIndex + n] = sector;
			writeIndex += n;
		}
		return r;
	}
}
/// 
unittest{
	import std.random : uniform;
	auto frame = RawFrame!5(72);
	Color[5 * GROUP_LEDS_COUNT][4] sequences;
	// fill sequences randomly
	foreach (i; 0 .. sequences.length){
		foreach(led; 0 .. sequences[i].length){
			sequences[i][led] = cast(Color)cast(ubyte)uniform(0, 4);
		}
	}
	// write sequences to RawFrame
	foreach (sector; 0 .. 72){
		frame.writeSector(cast(ubyte)sector, cast(Color[20])sequences[sector % sequences.length]);
	}
	// now read and match
	foreach (sector; 0 .. 72){
		Color[20] read = frame.readSector(cast(ubyte)sector);
		assert (read == cast(Color[20])sequences[sector % sequences.length]);
	}
}