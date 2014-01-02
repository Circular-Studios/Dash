module bootstrapper;
import core.runtime;

import std.stdio;

version( Windows )
import std.c.windows.windows;

void main()
{
	uint result;

	do
	{
		auto lib = Runtime.loadLibrary( "dvelop.dll" );

		version( Windows )
		{
			auto func = ( cast(uint function())GetProcAddress( lib, "_D4core4main10DGameEntryFZk" ) );
			result = func();
		}
		else version( Posix )
		{
			result = ( cast(uint function())dlsym( lib, "_D4core4main10DGameEntryFZk" ) )();
		}

		writeln( "Finished running. Result = ", result );

		//writeln( "Module unloaded. Result = ", Runtime.unloadLibrary( lib ) );

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
