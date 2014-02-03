module graphics.adapters.win32;

version( Windows ):

import core.dgame, core.gameobject, core.properties;
import components.mesh, components.assets;
import graphics.graphics, graphics.adapters.adapter, graphics.shaders.shaders, graphics.shaders.glshader;
import utility.input, utility.output;
import math.matrix;

import win32.windef, win32.winuser, win32.winbase;
import win32.wingdi : PIXELFORMATDESCRIPTOR, SetPixelFormat, SwapBuffers;
import derelict.opengl3.gl3, derelict.opengl3.wgl, derelict.opengl3.wglext;

enum DWS_FULLSCREEN = WS_POPUP | WS_SYSMENU;
enum DWS_WINDOWED = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU;

extern( Windows )
LRESULT WndProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
	switch( message )
	{
        case WM_CLOSE:
        case WM_DESTROY:
        case WM_QUIT:
			PostQuitMessage( 0 );
			break;
			// If key down, send it to input
        case WM_KEYDOWN:
			Input.setKeyState( cast(uint)wParam, true );
			break;
			// If key up, send it to input
        case WM_KEYUP:
			Input.setKeyState( cast(uint)wParam, false );
			break;
			// On Mouse Event
        case WM_RBUTTONDOWN:
			Input.setKeyState( VK_RBUTTON, true );
			break;
			// On Mouse Event
        case WM_RBUTTONUP:
			Input.setKeyState( VK_RBUTTON, false );
			break;
			// On Mouse Event
        case WM_LBUTTONDOWN:
			Input.setKeyState( VK_LBUTTON, true );
			break;
			// On Mouse Event
        case WM_LBUTTONUP:
			Input.setKeyState( VK_LBUTTON, false );
			break;
			// If no change, send to default windows handler
        default:
			return DefWindowProc( hWnd, message, wParam, lParam );
	}
	return 0;
}

class Win32 : Adapter
{
public:
	static @property Win32 get() { return cast(Win32)Graphics.adapter; }

	mixin Property!( "HWND", "hWnd" );
	mixin Property!( "HINSTANCE", "hInstance" );

	override void initialize()
	{
		// Load opengl functions
		DerelictGL3.load();

		// Setup the window
		screenWidth = GetSystemMetrics( SM_CXSCREEN );
		screenHeight = GetSystemMetrics( SM_CYSCREEN );
		
		hInstance = GetModuleHandle( null );
		
		WNDCLASSEX wcex = {
			WNDCLASSEX.sizeof,
				CS_HREDRAW | CS_VREDRAW,// | CS_OWNDC,
				&WndProc,
				0,
				0,
				hInstance,
				null,
				LoadCursor( null, IDC_ARROW ),
				cast(HBRUSH)( COLOR_WINDOW + 1 ),
				null,
				DGame.instance.title.ptr,
				null
		};
		
		RegisterClassEx( &wcex );
		openWindow( false );

		// Setup opengl		
		uint formatCount;
		int pixelFormat;
		PIXELFORMATDESCRIPTOR pfd;
		
		HGLRC handle;
		
		deviceContext = GetDC( hWnd );		
		SetPixelFormat( deviceContext, 1, &pfd );
		renderContext = wglCreateContext( deviceContext );
		wglMakeCurrent( deviceContext, renderContext );
		
		DerelictGL3.reload();
		
		if( DerelictGL3.loadedVersion < GLVersion.GL40 )
		{
			log( OutputType.Error, "Your version of OpenGL is unsupported. Required: GL40 Yours: ", DerelictGL3.loadedVersion );
			//throw new Exception( "Unsupported version of OpenGL." );
			return;
		}
		
		closeWindow();
		openWindow();
		
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
		deviceContext = GetDC( hWnd );
		
		// Query pixel format
		wglChoosePixelFormatARB( deviceContext, attributeList.ptr, null, 1, &pixelFormat, &formatCount );
		
		// Set the pixel format
		SetPixelFormat( deviceContext, pixelFormat, &pfd );
		
		// Create OpenGL rendering context
		renderContext = wglCreateContextAttribsARB( deviceContext, null, versionInfo.ptr );
		
		// Set current context
		wglMakeCurrent( deviceContext, renderContext );
		
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
		
		glClearColor( 0.0f, 0.0f, 0.0f, 1.0f );
	}

	override void shutdown()
	{
		wglMakeCurrent( null, null );
		wglDeleteContext( renderContext );
		renderContext = null;
		ReleaseDC( hWnd, deviceContext );
		deviceContext = null;
		closeWindow();
	}

	override void resize()
	{
		LONG style = GetWindowLong( hWnd, GWL_STYLE ) & ~( DWS_FULLSCREEN | DWS_WINDOWED );

		loadProperties();

		if( fullscreen )
		{
			width = screenWidth;
			height = screenHeight;
			style |= DWS_FULLSCREEN;
		}
		else
		{
			style |= DWS_WINDOWED;
		}

		SetWindowLong( hWnd, GWL_STYLE, style );
		SetWindowPos( hWnd, null, ( screenWidth - width ) / 2, ( screenHeight - height ) / 2,
					  width + ( 2 * GetSystemMetrics( SM_CYBORDER ) ),
					  height + GetSystemMetrics( SM_CYCAPTION ) + GetSystemMetrics( SM_CYBORDER ),
					  SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );

		glViewport( 0, 0, width, height );
		// update matricies
	}

	override void reload()
	{
		resize();
		
		// Enable back face culling
		if( backfaceCulling )
		{
			glEnable( GL_CULL_FACE );
			glCullFace( GL_BACK );
		}
		
		// Turn on of off the v sync
		wglSwapIntervalEXT( vsync );
	}

	override void beginDraw()
	{
		glBindFramebuffer( GL_FRAMEBUFFER, deferredFrameBuffer );
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

		//Set the shader and program for all draw calls for the first pass
		glUseProgram( (cast(GLShader)Shaders["deferred"]).programID );
	}

	override void drawObject( GameObject object )
	{
		glBindVertexArray( object.mesh.glVertexArray );

		GLShader shader = cast(GLShader)Shaders["deferred"];
		shader.setUniformMatrix( "world", object.transform.matrix );
		shader.setUniformMatrix( "worldViewProj", object.transform.matrix * Matrix!4.buildPerspective( 90, width / height, 0, 100 ) );

		//This is finding the uniform for the given texture, and setting that texture to the appropriate one for the object
		GLint textureLocation = glGetUniformLocation( shader.programID, "diffuseTexture" );
		glUniform1i( textureLocation, 0 );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, object.diffuse.glID );

		textureLocation = glGetUniformLocation( shader.programID, "normalTexture" );
		glUniform1i( textureLocation, 1 );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, object.normal.glID );
		
		glDrawElements( GL_TRIANGLES, object.mesh.numVertices, GL_UNSIGNED_INT, null );

		glBindVertexArray(0);
		glUseProgram(0);
	}

	override void endDraw()
	{
		//This line switches back to the default framebuffer
		glBindFramebuffer( GL_FRAMEBUFFER, 0 );
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

		GLShader shader = cast(GLShader)Shaders["deferredpass2"];
		glUseProgram( shader.programID );

		GLint textureLocation = glGetUniformLocation( shader.programID, "diffuseTexture" );
		glUniform1i( textureLocation, 0 );
		glActiveTexture( GL_TEXTURE0 );
		glBindTexture( GL_TEXTURE_2D, diffuseRenderTexture );

		textureLocation = glGetUniformLocation( shader.programID, "normalTexture" );
		glUniform1i( textureLocation, 1 );
		glActiveTexture( GL_TEXTURE1 );
		glBindTexture( GL_TEXTURE_2D, normalRenderTexture );

		textureLocation = glGetUniformLocation( shader.programID, "depthTexture" );
		glUniform1i( textureLocation, 2 );
		glActiveTexture( GL_TEXTURE2 );
		glBindTexture( GL_TEXTURE_2D, depthRenderTexture );

		glBindVertexArray( Assets.get!Mesh( "WindowMesh" ).glVertexArray );

		glDrawElements( GL_TRIANGLES, 6, GL_UNSIGNED_INT, null );

		SwapBuffers( deviceContext );
	}

	override void openWindow()
	{
		openWindow( true );
	}

	void openWindow( bool showWindow )
	{
		hWnd = CreateWindowEx( 0, DGame.instance.title.ptr, DGame.instance.title.ptr, fullscreen ? DWS_FULLSCREEN : DWS_WINDOWED,
							   ( screenWidth - width ) / 2, ( screenHeight - height ) / 2, width, height,
							  null, null, hInstance, null );

		assert( hWnd );

		resize();

		ShowWindow( hWnd, showWindow ? SW_NORMAL : SW_HIDE );
	}

	override void closeWindow()
	{
		DestroyWindow( hWnd );
		hWnd = null;
	}

	override void messageLoop()
	{
		MSG msg;

		// Initialize the message structure.
		( cast(byte*)&msg )[ 0 .. msg.sizeof ] = 0;

		// Handle the windows messages.
		while( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE ) )
		{
			TranslateMessage( &msg );
			DispatchMessage( &msg );
		}
	}
}
