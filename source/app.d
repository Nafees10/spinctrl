import std.stdio;
import std.file;
import std.path;
import core.stdc.stdlib : exit;
import std.conv : to;

import qui.qui;
import qui.widgets;

import utils.misc;
import utils.lists;

import ctrl;

/// default directory where images are read from
const string DEFAULT_IMG_DIR = "~/.local/spinctrl/";
/// path of command history file
const string COMMAND_HISTORY_PATH = "~/.local/spinctrl/.history";

/// safe RPM range, lower bound (inclusive)
const uint[2] RANGE_RPM = [1000,2000];
/// safe toggle time(micro-seconds) range (inclusive)
const ubyte[2] RANGE_TOGGLETIME = [0, 7]; // usually, it sits at 5.5-6 micro-seconds
/// safe degrees_lost range (inclusive)
const ubyte[2] RANGE_DEGLOST = [0, 8]; // anything above 8 is big bad, because that means <45 updates per rotation. 4 is ideal
/// background color when reading is outside range
const Color ABNORMAL_BG_COLOR = Color.red;
/// alternative text color
const Color ALT_FG = Color.green;

void main(string[] args){
	// tell the truth
	version (Windows){
		writeln("Windows bad, Linux good");
		exit(1);
	}
	// create DEFAULT_IMG_DIR if not exists, if doesnt work, give up
	const string defImgPath = expandTilde(DEFAULT_IMG_DIR);
	try{
		if (!exists(defImgPath)){
			mkdir(defImgPath);
		}else if (!isDir(defImgPath)){
			stderr.writeln("File '", defImgPath, "' already exists. Delete the file, and restart");
			exit(1);
		}
	}catch (Exception e){
		stderr.writeln("Failed to create directory '",defImgPath,"'. Check if you have enough privileges.");
		exit(1);
	}
	if (args.length > 1 && (args[1] == "--help" || args[1] == "-h")){
		writeln("Usage:\nspinctrl SERIAL/FILE/PATH [IMAGES/DIR]");
		writeln("By default, IMAGES/DIR is: ",DEFAULT_IMG_DIR);
		exit(0);
	}
	if (args.length < 2){
		stderr.writeln("Serial file not specified.");
		stderr.writeln("Usage:\nspinctrl SERIAL/FILE/PATH [IMAGES/DIR]");
		stderr.writeln("By default, IMAGES/DIR is: ",DEFAULT_IMG_DIR);
		exit(1);
	}
	// make sure files exists, and if IMAGES/DIR is specified, make sure its a directory, not a file
	string serialPath = args[1], imgDir = args.length > 2 ? args[2] : defImgPath;
	if (!exists(serialPath) || !isFile(serialPath)){
		stderr.writeln("path specified for serial file is invaid");
		exit(1);
	}
	if (!exists(imgDir) || !isDir(imgDir)){
		stderr.writeln("path specified for images-directory is invaid");
		exit(1);
	}
	// start the app
	App prog = new App(imgDir, serialPath);
	prog.run();
	.destroy(prog);
	exit(0);
}

/// runs the whole thing
class App{
private:
// widgets
	QTerminal _term; /// terminal
	QLayout _infoLayout; /// holds widgets showing status. Also used for timer events
	TextLabelWidget _labelRpm, _labelToggleTime, _labelDegLost, _labelFps; /// display RPM, toggleTime, degrees per update, FPS
	LogWidget _log; /// log of all input commands, and status
	ProgressbarWidget _progBar; /// display how much of a playing animation has been played
	QLayout _inputLayout; /// holds widgets for getting input
	TextLabelWidget _labelInput; /// to show where to input
	EditLineWidget _commandInput; /// used to input commands
// other vars
	string _dir;
	string _serialPath;
	File _serial;
	
	uinteger _rpm, _fps, _toggleTime, _degLost; /// stores last read values of  rpm, and toggleTime. _fps and _degLost are calculated
	uinteger _animationFramesPlayed, _animationFramesTotal; /// number of frams of an animation that have been played/total
	/// stores commands previously executed
	List!string _commandHistory;
	/// what index was previously selected from _commandHistory
	uinteger _commandHistoryIndex;
protected:
	/// interpretes commands, & gets them executed
	void execCommand(string command){

	}
	/// keyboard for _commandInput
	void commandKeyboard(QWidget widget, KeyboardEvent key){
		static string currentEntry = ""; /// stores what was entered before the user started using arrowUp/Down to select from history
		if (key.key == KeyboardEvent.Key.UpArrow && _commandHistoryIndex >= 0){
			if (_commandHistoryIndex >= _commandHistory.length){
				currentEntry = _commandInput.text;
				_commandHistoryIndex = _commandHistory.length;
			}
			if (_commandHistoryIndex > 0)
				_commandHistoryIndex --;
			if (_commandHistoryIndex < _commandHistory.length)
				_commandInput.text = _commandHistory.read(_commandHistoryIndex);
		}else if (key.key == KeyboardEvent.Key.DownArrow){
			if (_commandHistoryIndex < _commandHistory.length){
				_commandHistoryIndex ++;
				if (_commandHistoryIndex < _commandHistory.length)
					_commandInput.text = _commandHistory.read(_commandHistoryIndex);
				else
					_commandInput.text = currentEntry;
			}
		}else if (key.key == '\n' && _commandInput.text.length){
			_commandHistoryIndex = uinteger.max;
			_commandHistory.append(_commandInput.text);
			_log.add("> "~_commandInput.text);
			execCommand(_commandInput.text);
			_commandInput.text = "";
		}
	}
	/// timer event. Just using one timer event to update all widgets, avoiding loosing time in multiple function calls
	void timer(QWidget widget){
		// TODO: receive new stats from thread

		// update stat labels
		// first comes rpm
		_labelRpm.caption = "RPM:  "~_rpm.to!string;
		if (_rpm < RANGE_RPM[0] || _rpm > RANGE_RPM[1])
			_labelRpm.backgroundColor = ABNORMAL_BG_COLOR;
		else
			_labelRpm.backgroundColor = DEFAULT_BG;
		// then toggle time
		_labelToggleTime.caption = "ToggleTime:  "~_toggleTime.to!string;
		if (_toggleTime < RANGE_TOGGLETIME[0] || _toggleTime > RANGE_TOGGLETIME[1])
			_labelToggleTime.backgroundColor = ABNORMAL_BG_COLOR;
		else
			_labelToggleTime.backgroundColor = DEFAULT_BG;
		// then degrees lost
		_labelDegLost.caption = "DegreesLost:  "~_degLost.to!string;
		if (_degLost < RANGE_DEGLOST[0] || _degLost > RANGE_DEGLOST[1])
			_labelDegLost.backgroundColor = ABNORMAL_BG_COLOR;
		else
			_labelDegLost.backgroundColor = DEFAULT_BG;
		// and finally FPS
		_labelFps.caption = "FPS:  "~_fps.to!string; // no range, just display it
		
		// now for the animation progress bad
		if (_animationFramesTotal > 0){
			_progBar.max = _animationFramesTotal;
			_progBar.progress = _animationFramesPlayed;
			_progBar.caption = "Frames Played:  "~_animationFramesPlayed.to!string ~ " / "~_animationFramesTotal.to!string;
		}
	}
public:
	/// constructor
	/// 
	/// `dir` is the directory from where to read files from
	/// `serialPath` is the bluetooth serial file
	this(string dir, string serialPath){
		_dir = dir;
		_serialPath = serialPath;
		_commandHistory = new List!string;
		// try opening it
		if (exists(expandTilde(COMMAND_HISTORY_PATH))){
			const fileContents = fileToArray(expandTilde(COMMAND_HISTORY_PATH));
			_commandHistory.setFreeSpace(fileContents.length);
			foreach(line; fileContents){
				if (line != "")
					_commandHistory.append(line);
			}
		}
		_commandHistoryIndex = _commandHistoryIndex.max;
		// TODO: open the serial file

		// set up the UI
		_term = new QTerminal();
		_infoLayout = new QLayout(QLayout.Type.Horizontal);
		_labelRpm = new TextLabelWidget();
		_labelToggleTime = new TextLabelWidget();
		_labelFps = new TextLabelWidget();
		_labelDegLost = new TextLabelWidget();
		_log = new LogWidget();
		_progBar = new ProgressbarWidget(1,1);
		_inputLayout = new QLayout(QLayout.Type.Horizontal);
		_labelInput = new TextLabelWidget(">");
		_commandInput = new EditLineWidget();
		// arrange the elements
		_infoLayout.addWidget([_labelToggleTime, _labelRpm, _labelDegLost, _labelFps]);
		_inputLayout.addWidget([_labelInput, _commandInput]);
		_term.addWidget([_infoLayout, _log, _progBar, _inputLayout]);
		// set the input getters
		_inputLayout.size.maxHeight = 1;
		_labelInput.textColor = ALT_FG;
		_labelInput.size.maxWidth = 1;
		_commandInput.textColor = ALT_FG;
		// set progress bar
		_progBar.backgroundColor = DEFAULT_BG;
		_progBar.barColor = ALT_FG;
		_progBar.textColor = DEFAULT_FG;
		_progBar.size.maxHeight = 1;
		// register all widgets
		_term.registerWidget([_labelToggleTime, _labelRpm, _labelDegLost, _labelFps, _infoLayout, _log,
			 _progBar, _inputLayout, _labelInput, _commandInput]);
		// tie timer event to layout
		_infoLayout.onTimerEvent = &timer;
		// and the keyboard to _commandInput
		_commandInput.onKeyboardEvent = &commandKeyboard;
	}
	/// destructor
	~this(){
		// TODO: close the serial file
		// kill all the children (of the terminal)
		.destroy(_labelRpm);
		.destroy(_labelToggleTime);
		.destroy(_labelDegLost);
		.destroy(_labelFps);
		.destroy(_log);
		.destroy(_infoLayout);
		.destroy(_labelInput);
		.destroy(_inputLayout);
		.destroy(_commandInput);
		// now end the terminal itself
		.destroy(_term);
	}
	/// runs the whole thing
	void run(){
		_term.run;
		// save the command history file
		_commandHistory.toArray().arrayToFile(expandTilde(COMMAND_HISTORY_PATH));
	}
}