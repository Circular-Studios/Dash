module myclass;

import core.runtime;
import std.c.stdio;
import std.c.stdlib;
import std.string;
import std.c.windows.windows;

export MyClass getDGame()
{
	return new MyClass();
}

class MyClass
{
	int x;

	this()
	{
		x = 42;
	}

	public int test()
	{
		return x;
	}
}

extern( Windows )
BOOL DllMain( HINSTANCE hInstance, ULONG ulReason, LPVOID plReserved )
{
	final switch( ulReason )
	{
		case DLL_PROCESS_ATTACH:
			Runtime.initialize();
			break;
		case DLL_PROCESS_DETACH:
			Runtime.terminate();
			break;
	}

	return true;
}
