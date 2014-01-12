module graphics.windows.macx11;

version( OSX ):

import graphics.graphics;
import graphics.windows.windows;
import graphics.adapters.opengl.macx11gl;

import derelict.opengl3.gl3, derelict.opengl3.cgl;

import utility.output;

class MacX11 : Windows
{
public:
	static @property MacX11 get() { return cast(MacX11)Graphics.window; }

	override @property MacX11GL gl()
	{
		static MacX11GL opengl;
		if( opengl is null )
			opengl = new MacX11GL;
		
		return opengl;
	}

	override void initialize()
	{
		screenWidth = 800;
		screenHeight = 600;
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
