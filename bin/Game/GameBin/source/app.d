module myclass;

import core.runtime;
import std.stdio;
import std.c.stdlib;
import std.string;
import std.c.windows.windows;

extern (Windows)
BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    final switch (ulReason)
    {
        case DLL_PROCESS_ATTACH:
			Runtime.initialize();
			break;

        case DLL_PROCESS_DETACH:
			Runtime.terminate();
			break;

        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
			return false;
    }
    return true;
}

export class MyClass
{
export:
	int _x;

	this()
	{
		_x = 32;

		writeln( "MyClass.this()" );
	}

	@property int x() { return _x; }
	@property void x( int newX ) { _x = newX; }

	float test( int y, float z )
	{
		return _x * y * z;
	}
}
