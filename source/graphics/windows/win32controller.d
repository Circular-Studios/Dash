module graphics.windows.win32controller;
import core.graphosglobal;
import graphics.graphicscontroller;
import graphics.windows.windowcontroller;

import std.c.windows.windows;

version( Windows )
class Win32Controller : WindowController
{
public:
	static @property Win32Controller get() { return cast(Win32Controller)GraphicsController.window; }

	mixin( Property!( "HWND", "hWnd" ) );

	override void initialize()
	{

	}

	override void shutdown()
	{

	}

	override void resize()
	{

	}

	override void openWindow()
	{

	}

	override void closeWindow()
	{

	}

	override void messageLoop()
	{

	}
}
