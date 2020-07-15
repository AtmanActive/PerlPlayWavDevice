# PerlPlayWavDevice
Windows utility to play a given 8-bit wav file to a given audio device.
It can be useful for batch files or other automation tasks.

Usage (command line arguments):

-h, --help, /? for this info

-l, --list to list available devices

Sound file name or path as first argument, will use portable path if only filename provided

Optional output device partial name or number as second argument, will try to match with regex

-i, --info as optional third argument to show wav file properties

Due to unknown deficiencies of the underlying libraries, it works correctly with 8-bit files only. Nevertheless, for short signal noises or audio feedback it is still quite usable. Just need to remember to convert your wav files to 8 bits, mono or stereo.
