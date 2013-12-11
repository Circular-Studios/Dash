module graphics.adapters.opengl;
import core.global;
import graphics.graphics, graphics.adapters.adapter;

import derelict.opengl3.gl3;

version( Windows )
{
	alias HGLRC GLRenderContext;
}
else
{
	alias OpenGLRenderContext GLRenderContext;
}

class OpenGL : Adapter
{
public:
	mixin( Property!( "GLRenderContext", "renderContext" ) );

	override void initialize()
	{
		Graphics.window.initialize();
		Graphics.window.openWindow();

		uint formatCount;
		int pixelFormat[ 1 ];
		

		DerelictGL3.load();

		

		DerelictGL3.reload();
	}

	override void shutdown()
	{

	}

	override void resize()
	{

	}

	override void reload()
	{

	}

	override void beginDraw()
	{

	}
	override void endDraw()
	{

	}

private:

}
