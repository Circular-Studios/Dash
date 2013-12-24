module scripting.scripts;
import utility.config, utility.filepath, utility.output;

import core.runtime, core.demangle;
import std.conv;

version( Windows )
{
	import std.c.windows.windows;
}

static class Scripts
{
static:
public:
	version( Windows )
	{
		HMODULE scriptDll;

		void initialize()
		{
			scriptDll = cast(HMODULE)Runtime.loadLibrary( FilePath.ResourceHome ~ Config.get!string( "Scripts.FilePath" ) );

			if( scriptDll is null )
			{
				Output.printMessage( OutputType.Error, "Error loading dll file." );
			}
		}

		TReturn callFunction( TReturn )( TReturn function() func )
		{
			return (*(cast(TReturn function())GetProcAddress( scriptDll, func.mangleof.ptr )))();
		}

		TReturn callFunction( TReturn, TArgs... )( TReturn function( TArgs ) func, TArgs args )
		{
			return (*(cast(TReturn function( TArgs ))GetProcAddress( scriptDll, func.mangleof.ptr )))( args );
		}

		TReturn callFunction( TReturn )( string mangledName )
		{
			return (*(cast(TReturn function())GetProcAddress( scriptDll, mangledName.ptr )))();
		}

		void shutdown()
		{
			Runtime.unloadLibrary( scriptDll );
		}
	}
}
