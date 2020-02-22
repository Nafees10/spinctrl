module spinctrl.ctrl;

import std.conv : to;
import std.concurrency;
import core.thread;

import utils.misc;

import spinctrl.serialio;

/// message between UI thread and ctrl thread
public struct CtrlMessage{
	/// Types of messages
	enum Type{
		DrawImage, /// draw a full image. Only PNG works. JPEG bad
		DrawAnimation, /// draws a GIF
		DrawText, /// draws text
		DrawOnboard, /// draws a built in animation/image
		Peek, /// Jump to a frame in an animation
		ToggleLoadingAnimation, /// sets Loading animation on/off
		SetFPS, /// skip frames to lower FPS to `this.fps`
		Clear, /// Clear the display
		StartCalibration, /// stop displaying, start measuring RPM & ToggleTime while displaying some builtin image
		StopCalibration, /// back to displaying, and send the average RPM & ToggleTime back soon (with this.Type.Status)
		Terminate, /// ownerTid telling ctrl to terminate
		Status, /// sending status from ctrl to UI
		Log, /// sending text from ctrl to UI to display on log
	}
	/// Stores type of this message
	Type type;
	public union{
		/// stores image path for this.Type.DrawImage && this.Type.DrawAnimation
		public string imgPath;
		/// stores text to display for this.Type.DrawText, or for Log
		public string text;
		/// stores name of animation for this.Type.DrawOnboard
		public string onboardName;
		/// where to peek to, for this.Type.Peek
		public ushort peek;
		/// whether to turn loading animation on/off
		bool loadingAnimation;
		/// status struct
		public struct{
			ubyte toggleTime; /// average micro seconds to switch 1 pin from LOW->HIGH or HIGH->LOW. Only valid for Type.Status
			ushort RPM; /// calculated RPM. Only valid for Type.Status
			ushort frame; /// what frame is curerntly being displayed
			ushort frameTotal; /// total number of frames
			ubyte sectorCount; /// number of times LED strip updated in 1 revolution

			ushort calculatedFps; /// FPS (drawings per second) calculated using RPM, done locally, not by spinner
		}
		/// fps to set it to. For this.Type.FPS
		public ubyte fps;
	}

	/// Calculates FPS using RPM
	void calculateFps(){
		this.calculatedFps = this.RPM / 60;
	}

	/// Returns: readable string representing this struct
	public string prettyString(){
		if (type == Type.DrawImage){
			return "Draw Image : "~this.imgPath;
		}else if (type == Type.DrawAnimation){
			return "Draw Animation : "~this.imgPath;
		}else if (type == Type.DrawText){
			return "Draw Text : "~this.text;
		}else if (type == Type.DrawOnboard){
			return "Draw Onboard : "~this.onboardName;
		}else if (type == Type.Peek){
			return "Peek : "~this.peek.to!string;
		}else if (type == Type.ToggleLoadingAnimation){
			return "Loading Animation : "~(this.loadingAnimation ? "on" : "off");
		}else if (type == Type.SetFPS){
			return "Set FPS : "~this.fps.to!string;
		}else if (type == Type.Clear){
			return "Clear Display";
		}else if (type == Type.StartCalibration){
			return "Staring Calibration";
		}else if (type == Type.StopCalibration){
			return "Stopping Calibration - awaiting results";
		}else if (type == Type.Terminate){
			return "Terminating";
		}else if (type == Type.Status){
			return "RPM : "~this.RPM.to!string~"   toggle time : "~this.toggleTime.to!string~"   frame : "~this.frame.to!string;
		}
		return "";
	}
}

/// to be run in separate thread from main.
/// 
/// Awaits `ctrl.Message`, executes received commands. Frequently, sends back RPM and toggleTime
void ctrlThread(){
	Tid serialThread = spawn(&serialIOThread);
	
}