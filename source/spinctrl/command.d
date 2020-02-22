module spinctrl.command;

import utils.misc;

import std.file;
import std.path;
import std.range;
import std.conv : to;

import spinctrl.ctrl : CtrlMessage;
import spinctrl.texted : canDisplay;

/// List of all valid commands
private const string[] COMMANDS = [
	"upload", /// to upload regular image
	"uploadgif", /// to upload a GIF
	"text", /// display some text
	"onboard", /// display some built in animation/image
	"peek", /// jump to a frame in an animation
	"setfps", /// set FPS for a GIF. Cannot use this to exceed max, but can decrease it
	"clear", /// clear screen
	"calibrate", /// stop/start calibration
	"loading", /// toggle loading animation on/off
];

/// Type of args a command can accept
/// 
/// "pngFile" means valid file path where a PNG image is located  
/// "gifFile" means valid file path where a GIF image is located  
/// "int" means an integer  
/// "bool" means 1 or 0  
/// "text" means printable ASCII characters  
/// "" means no arg
private const string[string] COMMAND_ARG_TYPES;

/// module constructor
static this(){
	COMMAND_ARG_TYPES = [
		"upload" : "pngFile",
		"uploadgif" : "gifFile",
		"text" : "text",
		"onboard" : "text",
		"peek" : "int",
		"setfps" : "int",
		"clear" : "",
		"calibrate" : "bool",
		"loading" : "bool"
	];
}

/// Reads a command into a CtrlMessage that can be sent to ctrlThread
/// 
/// In case of any error, it is written to `error`, else, error == "true" = true
/// 
/// Returns: the CtrlMessage.
public CtrlMessage readCommand(string commandStr, string imgDir, ref string error){
	CtrlMessage r;
	string command, arg;
	{
		const string[] commandWords = commandStr.readWords;
		command = commandWords.length > 0 ? commandWords[0].lowercase : "";
		arg = commandWords.length > 1 ? commandWords[1] : "";
	}
	if (!COMMANDS.hasElement(command)){
		error = "unknown command";
		return r;
	}
	error = checkCommandArgs(command, arg, imgDir);
	if (error.length > 0)
		return r;
	if (command == "upload"){
		r.type = CtrlMessage.Type.DrawImage;
		r.imgPath = arg;
	}else if (command == "uploadgif"){
		r.type = CtrlMessage.Type.DrawAnimation;
		r.imgPath = arg;
	}else if (command == "text"){
		r.type = CtrlMessage.Type.DrawText;
		r.text = arg;
	}else if (command == "onboard"){
		r.type = CtrlMessage.Type.DrawOnboard;
		r.onboardName = arg;
	}else if (command == "peek"){
		r.type = CtrlMessage.Type.Peek;
		r.peek = arg.to!ushort;
	}else if (command == "setfps"){
		r.type = CtrlMessage.Type.SetFPS;
		r.fps = arg.to!ubyte;
	}else if (command == "clear"){
		r.type = CtrlMessage.Type.Clear;
	}else if (command == "calibrate" && arg == "1"){
		r.type = CtrlMessage.Type.StartCalibration;
	}else if (command == "calibrate" && arg == "0"){
		r.type = CtrlMessage.Type.StopCalibration;
	}else if (command == "loading"){
		r.type = CtrlMessage.Type.ToggleLoadingAnimation;
		r.loadingAnimation = arg == "1" ? true : false;
	}
	return r;
}

/// Checks if arguments for a command are valid
/// 
/// Returns: "" if no error, othewise, error is contained in returned string
private string checkCommandArgs(string command, ref string arg, string imgDir){
	if (COMMANDS.hasElement(command)){
		const string validType = COMMAND_ARG_TYPES[command];
		if (validType == "pngFile" || validType == "gifFile"){
			arg = imgDir ~ arg;
			if (!exists(arg) || !isFile(arg))
				return command~": Invalid file path specified";
		}else if (validType == "int"){
			if (!isNum(arg, false))
				return command~": Argument must be integer";
		}else if (validType == "bool"){
			if (arg != "0" && arg != "1")
				return command~": Argument must be boolean(1 or 0)";
		}else if (validType == "text"){
			if (arg.length == 0 || !canDisplay(arg))
				return command~": Cannot display provided character(s)";
		}else if (validType == ""){
			return "";
		}
	}
	return "";
}

/// Reads a string into separate words
/// 
/// Returns: the words in a string[] excluding separator characters
private string[] readWords(string str){
	if (str.length == 0)
		return cast(string[])[];
	string[] r = [];
	str = str.dup;
	if (str[$-1] != ' ')
		str ~= ' ';
	for (uinteger i = 0, readFrom = 0; i < str.length; i ++){
		if (str[i] == ' '){
			if (readFrom < i)
				r ~= str[readFrom .. i];
			readFrom = i + 1;
		}
	}
	return r;
}
///
unittest{
	assert("potato potato".readWords == ["potato", "potato"]);
	assert(" potato      potato    ".readWords == ["potato", "potato"]);
}