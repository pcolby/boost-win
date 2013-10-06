# Building Boost on Windows

See [original blog post](http://colby.id.au/building-boost-on-windows) for background.

## Process Overview

The [build.cmd](build.cmd) script implements the following process:

1. Download and install the necessary tools.
2. Download the sources.
3. Download the build script.
4. Update paths and version numbers in the build script, as necessary.
5. Run the build script.

The build script itself will, for each build type (release / debug, 32-bit / 64-bit):

1. Extract the Boost source to a build sub-directory.
2. Configure the Windows SDK for the appropriate build type, if necessary.
3. Configure and build Boost.

## External Tools

Tip: you can find direct links to most of the software listed below on the
[Boost Links](http://colby.id.au/boost-links) page.

The build script requires a valid Visual C++ installation - Express editions are fine. If using an Express edition prior to 2012, then you should also install a recent (eg 7.1) Windows SDK for 64-bit support.

For Boost's MPI support, install a Microsoft HPC Pack - not 2012 though, that version does not include the required headers / libraries.

For Python support, install the official Python Windows binaries - install both 32-bit and 64-bit versions.

Oh, and the build script uses 7zip to extract the various sources, so install that too.

## Sources

At the very least you need the relevant Boost source... naturally.

Additionally, you can (recommended) include bzip2 and zlib sources to enable Boost's support for those. Note, if downloading zlib, be sure to downoad the source, not the compiled DLL release for Windows - the latter is 32-bit only.

My Boost build script expects to find the above sources within a source directory in its current location. The directory layout should look like:

* `source`
 * `boost_?_??_?.7z`
 * `bzip2-?.?.?.tar.gz`
 * `zlib???.zip`
* `build.cmd`

The build script will create a build directory (if not already present) for the generated build files.

## See Also
* [Building Boost on Windows](http://colby.id.au/building-boost-on-windows)
