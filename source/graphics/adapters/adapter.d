module graphics.adapters.adapter;
import core.properties;

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

	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();

	abstract void beginDraw();
	abstract void endDraw();

	abstract void openWindow();
	abstract void closeWindow();
	
	abstract void messageLoop();
}
