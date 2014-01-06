module bootstrapper;
version( Bootstrapper ):

import core.runtime;
import std.stdio;

version( Windows )
	import std.c.windows.windows;
else
	import core.sys.posix.dlfcn;

enum RunResult : uint
{
	Exit = 0,
	Reset = 1
}

void main()
{
	RunResult result;
	string libPath;

	version( Windows )
		libPath = "dvelop.dll";
	else
		libPath = "libdvelop.so";

	write( "If you want to debug, attach to bootstrapper.exe, then press enter." );
	readln();

	do
	{
		auto lib = Runtime.loadLibrary( libPath );

		if( lib is null )
		{
			writeln( "Unable to find library: ", libPath );
			break;
		}

		uint function() dGameEntry;

		version( Windows )
		{
			dGameEntry = cast(uint function())GetProcAddress( lib, "_D4core4main10DGameEntryFZk" );
		}
		else version( Posix )
		{
			dGameEntry = cast(uint function())dlsym( lib, "_D4core4main10DGameEntryFZk" );
		}

		result = cast(RunResult)dGameEntry();

		Runtime.unloadLibrary( lib );

		final switch( result )
		{
			case RunResult.Exit:
				// Exited successfully.
				break;
			case RunResult.Reset:
				// Need to reset;
				write( "Press enter to continue resetting." );
				readln();
				break;
		}
	} while( result == RunResult.Reset );
}
