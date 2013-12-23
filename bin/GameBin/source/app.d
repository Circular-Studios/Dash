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

HINSTANCE g_hInst;

extern( Windows )
BOOL DllMain( HINSTANCE hInstance, ULONG ulReason, LPVOID plReserved )
{
	final switch( ulReason )
	{
		case DLL_PROCESS_ATTACH:
			printf("DLL_PROCESS_ATTACH\n");
			Runtime.initialize();
			break;
			
		case DLL_PROCESS_DETACH:
			printf("DLL_PROCESS_DETACH\n");
			Runtime.terminate();
			break;
			
		case DLL_THREAD_ATTACH:
			printf("DLL_THREAD_ATTACH\n");
			return false;
			
		case DLL_THREAD_DETACH:
			printf("DLL_THREAD_DETACH\n");
			return false;
	}

	g_hInst = hInstance;
	return TRUE;
}

static this()
{
	printf("static this for mydll\n");
}

static ~this()
{
	printf("static ~this for mydll\n");
}
