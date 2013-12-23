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
		auto h = cast(HMODULE)Runtime.loadLibrary( "bin/GameBin/gamebin_d.dll" );

		if( h is null )
		{
			Output.printMessage( OutputType.Error, "Error loading dll file." );
		}

		//auto mc = new MyClass;

		alias MyClass function() gameCtor;

		//const char[] name = demangle( "myclass.getDGame" );
		string name = getDGame.mangleof;
		//string name = "_D7myclass8getDGameFZC7myclass7MyClass";
		FARPROC fp = GetProcAddress( h, name.ptr );

		auto ctor = cast(gameCtor)fp;

		Object test = (*ctor)();

		//Output.printMessage( OutputType.Info, "Result from mc: " ~ mc.test().to!string );

		if( test is null )
		{
			Output.printMessage( OutputType.Error, "Error creating class instance." );
		}
	}
}
