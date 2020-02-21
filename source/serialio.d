module serialio;

import std.conv : to;
import std.concurrency;
import core.thread;

import utils.misc;
/// message between ctrl thread and serial i/0 thread

