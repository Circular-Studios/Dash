module bootstrapper;
import core.runtime;

import std.stdio;

version( Windows )
import std.c.windows.windows;

void main()
{
	uint result;
	string libPath = "dvelop.dll";

	do
	{
		auto lib = Runtime.loadLibrary( libPath );

		if( lib is null )
		{
			writeln( "Unable to find library: ", libPath );
			break;
		}

		writeln( "About to run game..." );

		version( Windows )
		{
			result = ( cast(uint function())GetProcAddress( lib, "_D4core4main10DGameEntryFZk" ) )();
		}
		else version( Posix )
		{
			result = ( cast(uint function())dlsym( lib, "_D4core4main10DGameEntryFZk" ) )();
		}

		writeln( "Finished running. Result = ", result );

		writeln( "Module unloaded. Result = ", Runtime.unloadLibrary( lib ) );

		final switch( result )
		{
			case 0:
				// Exited successfully.
				break;
			case 1:
				// Need to reset;
				readln();
				break;
		}
	} while( result == 1 );
}
