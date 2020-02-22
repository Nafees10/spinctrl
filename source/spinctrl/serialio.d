module spinctrl.serialio;

import std.conv : to;
import std.concurrency;
import core.thread;

import utils.misc;


/// message between ctrl thread and serial i/0 thread
package struct IOMessage{

}

/// Runs the serial IO thread, feeding the spinner's bluetooth serial with data
package void serialIOThread(){

}