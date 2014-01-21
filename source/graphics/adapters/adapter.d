module graphics.adapters.adapter;
import core.gameobject, core.properties;
import utility.config;

version( Windows )
{
	import win32.windef;
	
	alias HGLRC GLRenderContext;
	alias HDC GLDeviceContext;
}
else version( OSX )
{
	import derelict.opengl3.gl3, derelict.opengl3.cgl;
	
	alias CGLContextObj GLRenderContext;
	alias uint GLDeviceContext;
}
else
{
	import derelict.opengl3.glx, derelict.opengl3.glxext;;
	
	//alias OpenGLRenderContext GLRenderContext;
	alias GLXContext GLRenderContext;
	alias uint GLDeviceContext;
}

abstract class Adapter
{
public:
	// Graphics contexts
	mixin Property!( "GLDeviceContext", "deviceContext", "protected" );
	mixin Property!( "GLRenderContext", "renderContext", "protected" );

	mixin Property!( "uint", "width", "protected" );
	mixin Property!( "uint", "screenWidth", "protected" );
	mixin Property!( "uint", "height", "protected" );
	mixin Property!( "uint", "screenHeight", "protected" );
	mixin Property!( "bool", "fullscreen", "protected" );
	mixin Property!( "bool", "backfaceCulling", "protected" );
	mixin Property!( "bool", "vsync", "protected" );

	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();

	abstract void beginDraw();
	abstract void drawObject( GameObject obj );
	abstract void endDraw();

	abstract void openWindow();
	abstract void closeWindow();
	
	abstract void messageLoop();

protected:
	void loadProperties()
	{
		fullscreen = Config.get!bool( "Display.Fullscreen" );
		if( fullscreen )
		{
			width = screenWidth;
			height = screenHeight;
		}
		else
		{
			width = Config.get!uint( "Display.Width" );
			height = Config.get!uint( "Display.Height" );
		}

		backfaceCulling = Config.get!bool( "Graphics.BackfaceCulling" );
		vsync = Config.get!bool( "Graphics.VSync" );
	}
}
