module core.main;
import core.dgame;

import std.stdio;
import core.runtime, core.memory;

export uint DGameEntry()
{
	if( !mainGame )
		mainGame = new DGame;

	mainGame.run();

	GC.collect();

	if( mainGame.currentState == GameState.Reset )
		return 1;
	else
		return 0;
}

version( Windows )
{
	import std.c.windows.windows;

	extern( Windows )
	BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
	{
		_fcloseallp = null;

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
	void main()
	{
		
	}
}
