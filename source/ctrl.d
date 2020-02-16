module ctrl;

import std.conv : to;
import std.concurrency;
import core.thread;

import utils.misc;

/// message between UI thread and ctrl thread
public struct Message{
	/// Types of messages
	enum Type{
		DrawImage, /// draw a full image. Only PNG works. JPEG bad
		DrawAnimation, /// draws a GIF
		Status, /// sending status from ctrl to UI
		SetFrameSkipping, /// set it to skip `frameSkipCount` frames after `frameCount` frames
	}
	/// Stores type of this message
	Type type;
	public union{
		/// stores image path for this.Type.DrawImage && this.Type.DrawAnimation
		public string imgPath;
		public union{
			uint toggleTime; /// average micro seconds to switch 1 pin from LOW->HIGH or HIGH->LOW. Only valid for Type.Status
			uint frameSkipCount; /// number of frames to skip every `frameCount`
		}
		public union{
			uint RPM; /// calculated RPM. Only valid for Type.Status
			uint frameCount; /// number of frames after `frameSkipCount` frames are skipped
		}
	}
}

