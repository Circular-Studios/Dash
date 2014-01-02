module core.main;
import core.dgame;
import utility.output;

import std.stdio;

import core.runtime;

version( Windows )
{
	import std.c.windows.windows;

	extern( Windows )
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
}
else version( Posix )
{

}

export uint DGameEntry()
{
	if( !mainGame )
		mainGame = new DGame;

	mainGame.run();

	return 0;
}
