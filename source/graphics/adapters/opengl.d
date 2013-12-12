module graphics.adapters.opengl;
import core.global;
import graphics.graphics;
import graphics.windows.win32;
import graphics.adapters.adapter;

import win32.windef, win32.winuser;
import win32.wingdi : PIXELFORMATDESCRIPTOR, SetPixelFormat;
import derelict.opengl3.gl3, derelict.opengl3.wgl;

version( Windows )
{
	alias HGLRC GLRenderContext;
	alias HDC GLDeviceContext;
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
		DerelictGL3.load();

		uint formatCount;
		int pixelFormat[ 1 ];
		PIXELFORMATDESCRIPTOR pfd;

		version( Windows )
		{
			deviceContext.gl = GetDC( Win32.get().hWnd );
			SetPixelFormat( deviceContext.gl, 1, &pfd );
			renderContext = wglCreateContext( deviceContext.gl );
		}
		else
		{

		}
		

		//DerelictGL3.reload();
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
