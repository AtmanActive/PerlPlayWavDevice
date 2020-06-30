# PerlPlayWavDevice
Windows utility to play a given wav file to a given audio device.
It can be useful for batch files or other automation tasks.

Usage (command line arguments):

-h, --help, /? for this info

-l, --list to list available devices

Sound file name or path as first argument, using portable path when only filename provided

Optional output device partial name or number as second argument, will try to match with regex

-i, --info as optional third argument to show wav file properties

