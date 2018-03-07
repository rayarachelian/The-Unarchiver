![Icon](http://wakaba.c3.cx/images/unarchiver_icon.png)

# NOTE

This is a fork of a specific mercurial branch of "The Unarchiver" by David Ryskalczyk which is available here:

[The Unarchiver DART branch](https://bitbucket.org/david_rysk/theunarchiver/commits/abe75473b0b8c2301821d2b8097d0cf351cd9516?at=DART)

This version is able to properly decompress an LZH compressed DART disk image and convert it into a Disk Copy 4.2 disk image properly without the bugs in the LZH code used by libdc42.

The hope is that I'll eventually be able to wrap a GUI around this either with GNUStep or with wxWidgets so it can also work on Linux and Windows in addition to just OS X, and ofc integrate it into libdc42.

However, the application itself (The Unarchiver) is Mac OS X only.  The command line utilities lsar and unar in the XADMaster directory do compile on Linux with the changed Makefiles and produce usable binaries, so I'm making these available here for now.

On Ubuntu you'll want to install the gnustep-devel package as a dependency (along with gnustep-base openssl bzip2 icu gcc-libs zlib).

--->8 --- original README.md below: --- 8< ---

# The Unarchiver is an Objective-C application for uncompressing archive files.

* Supports more formats than I can remember. Zip, Tar, Gzip, Bzip2, 7-Zip, Rar, LhA, StuffIt, several old Amiga file and disk archives, CAB, LZX, stuff I don't even know what it is. Read [the wiki page](http://code.google.com/p/theunarchiver/wiki/SupportedFormats) for a more thorough listing of formats.
* Copies the Finder file-copying/moving/deleting interface for its interface.
* Uses character set autodetection code from Mozilla to auto-detect the encoding of the filenames in the archives.
* Supports split archives for certain formats, like RAR.
* Version 2.0 uses an archive-handling library built largely from scratch in Objective-C, which makes adding support for new formats and algorithms very easy.
* Uses libxad (http://sourceforge.net/projects/libxad/) for older and more obscure formats. This is an old Amiga library for handling unpacking of archives.
* The unarchiving engine itself is multi-platform, and command-line tools exist for Linux, Windows and other OSes.
