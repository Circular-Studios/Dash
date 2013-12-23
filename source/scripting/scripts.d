module scripting.scripts;
import utility.output;

import myclass;

import core.runtime, core.demangle;
import utility.config;

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
			scriptDll = cast(HMODULE)Runtime.loadLibrary( Config.get!string( "Scripts.FilePath" ) );

			if( scriptDll is null )
			{
				Output.printMessage( OutputType.Error, "Error loading dll file." );
			}

			FARPROC fp = GetProcAddress( scriptDll, getDGame.mangleof.ptr );

			auto ctor = cast(MyClass function())fp;
			Object test = (*ctor)();

			if( test is null )
			{
				Output.printMessage( OutputType.Error, "Error creating class instance." );
			}
		}

		void shutdown()
		{
			Runtime.unloadLibrary( scriptDll );
		}
	}
}
