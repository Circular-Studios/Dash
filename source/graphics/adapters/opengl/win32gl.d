module graphics.adapters.opengl.win32gl;

version( Windows ):

import graphics.graphics;
import graphics.adapters.opengl.opengl;
import graphics.windows.win32;

import win32.windef, win32.winuser;
import win32.wingdi : PIXELFORMATDESCRIPTOR, SetPixelFormat, SwapBuffers;
import derelict.opengl3.gl3, derelict.opengl3.wgl, derelict.opengl3.wglext;

class Win32Gl : OpenGL
{
public:
	override void initialize()
	{
		Graphics.window.initialize();
		Graphics.window.openWindow();
		DerelictGL3.load();

		uint formatCount;
		int pixelFormat;
		PIXELFORMATDESCRIPTOR pfd;

		HGLRC handle;
		
		glDeviceContext = GetDC( Win32.get().hWnd );		
		SetPixelFormat( glDeviceContext, 1, &pfd );
		renderContext = wglCreateContext( glDeviceContext );
		wglMakeCurrent( glDeviceContext, renderContext );
		
		DerelictGL3.reload();
		
		Graphics.window.closeWindow();
		Graphics.window.openWindow();
		
		// Set attributes list
		const(int)[ 19 ] attributeList = [
			WGL_SUPPORT_OPENGL_ARB,	TRUE,						// Support for OpenGL rendering
			WGL_DRAW_TO_WINDOW_ARB,	TRUE,						// Support for rendering window
			WGL_ACCELERATION_ARB,	WGL_FULL_ACCELERATION_ARB,	// Support for hardware acceleration
			WGL_COLOR_BITS_ARB,		24,							// Support for 24bit color
			WGL_DEPTH_BITS_ARB,		24,							// Support for 24bit depth buffer
			WGL_DOUBLE_BUFFER_ARB,	TRUE,						// Support for double buffer
			WGL_SWAP_METHOD_ARB,	WGL_SWAP_EXCHANGE_ARB,		// Support for swapping buffers
			WGL_PIXEL_TYPE_ARB,		WGL_TYPE_RGBA_ARB,			// Support for RGBA pixel type
			WGL_STENCIL_BITS_ARB,	8,							// Support for 8 bit stencil buffer
			0													// Null terminate
		];
		
		// Set version to 4.0
		const(int)[ 5 ] versionInfo = [
			WGL_CONTEXT_MAJOR_VERSION_ARB, 4,
			WGL_CONTEXT_MINOR_VERSION_ARB, 0,
			0
		];
		
		// Get new Device Context
		glDeviceContext = GetDC( Win32.get().hWnd );
		
		// Query pixel format
		wglChoosePixelFormatARB( glDeviceContext, attributeList.ptr, null, 1, &pixelFormat, &formatCount );
		
		// Set the pixel format
		SetPixelFormat( glDeviceContext, pixelFormat, &pfd );
		
		// Create OpenGL rendering context
		renderContext = wglCreateContextAttribsARB( glDeviceContext, null, versionInfo.ptr );
		
		// Set current context
		wglMakeCurrent( glDeviceContext, renderContext );

		// Set depth buffer
		glClearDepth( 1.0f );
		
		// Enable depth testing
		glEnable( GL_DEPTH_TEST );
		
		// Enable transparency
		glEnable( GL_BLEND );
		glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
		
		// Set front face
		glFrontFace( GL_CW );
		
		reload();
		
		glClearColor( 0.5f, 0.5f, 0.5f, 1.0f );
	}

	override void shutdown()
	{
		wglMakeCurrent( null, null );
		wglDeleteContext( renderContext );
		renderContext = null;
		ReleaseDC( Win32.get().hWnd, glDeviceContext );
		glDeviceContext = null;
	}

	override void endDraw()
	{
		SwapBuffers( glDeviceContext );
	}

private:
}
