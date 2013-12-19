module scripting.scripts;
import utility.output;

import myclass;

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
	void initialize()
	{
		auto h = cast(HMODULE)Runtime.loadLibrary( "bin/GameBin/gamebin.dll" );

		if( h is null )
		{
			Output.printMessage( OutputType.Error, "Error loading dll file." );
		}

		//auto mc = new MyClass;

		FARPROC fp = GetProcAddress( h, "_D7myclass7MyClass7__ClassZ" );

		auto ctor = cast( MyClass function() )fp;

		auto test = (*ctor)();

		//Output.printMessage( OutputType.Info, "Result from mc: " ~ mc.test().to!string );

		if( test is null )
		{
			Output.printMessage( OutputType.Error, "Error creating class instance." );
		}
	}
}
