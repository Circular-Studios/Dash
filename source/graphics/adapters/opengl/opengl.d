module graphics.adapters.opengl.opengl;
import core.properties;
import graphics.graphics;
import graphics.adapters.adapter;
import utility.config;

import derelict.opengl3.gl3;

version( Windows )
{
	import win32.windef;

	alias HGLRC GLRenderContext;
	alias HDC GLDeviceContext;
}
else
{
	//alias OpenGLRenderContext GLRenderContext;
	alias uint GLRenderContext;
	alias uint GLDeviceContext;
}

abstract class OpenGL : Adapter
{
public:
	mixin Property!( "GLRenderContext", "renderContext", "protected" );

	override void resize()
	{
		glViewport( 0, 0, Graphics.window.width, Graphics.window.height );
	}

	override void reload()
	{
		resize();

        // Enable back face culling
		if( Config.get!bool( "Graphics.BackfaceCulling" ) )
        {
			glEnable( GL_CULL_FACE );
			glCullFace( GL_BACK );
        }

        // Turn on of off the v sync
        //wglSwapIntervalEXT( Config.getData!bool( "graphics.vsync" ) );
	}

	override void beginDraw()
	{
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	}

private:

}
