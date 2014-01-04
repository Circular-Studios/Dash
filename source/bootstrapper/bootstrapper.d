module bootstrapper;
version( Bootstrapper ):

import core.runtime;
import std.stdio;

version( Windows )
import std.c.windows.windows;

enum RunResult : uint
{
	Exit = 0,
	Reset = 1
}

void main()
{
	RunResult result;
	string libPath = "dvelop.dll";

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

		version( Windows )
		{
			result = cast(RunResult)( cast(uint function())GetProcAddress( lib, "_D4core4main10DGameEntryFZk" ) )();
		}
		else version( Posix )
		{
			result = ( cast(uint function())dlsym( lib, "_D4core4main10DGameEntryFZk" ) )();
		}

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
