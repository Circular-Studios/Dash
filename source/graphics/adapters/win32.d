module graphics.adapters.win32;

version( Windows ):

import core, graphics, utility;

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

shared final class Win32 : Adapter
{
private:
	HWND _hWnd;
	HINSTANCE _hInstance;

public:
	mixin( Property!_hWnd );
	mixin( Property!_hInstance );

	static @property Win32 get() { return cast(Win32)Graphics.adapter; }

	override void initialize()
	{
		// Load opengl functions
		DerelictGL3.load();

		// Setup the window
		screenWidth = GetSystemMetrics( SM_CXSCREEN );
		screenHeight = GetSystemMetrics( SM_CYSCREEN );
		
		hInstance = cast(shared)GetModuleHandle( null );
		
		WNDCLASSEX wcex = {
			WNDCLASSEX.sizeof,
				CS_HREDRAW | CS_VREDRAW,// | CS_OWNDC,
				&WndProc,
				0,
				0,
				cast(void*)hInstance,
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
		
		deviceContext = cast(shared)GetDC( cast(void*)hWnd );		
		SetPixelFormat( cast(void*)deviceContext, 1, &pfd );
		renderContext = cast(shared)wglCreateContext( cast(void*)deviceContext );
		wglMakeCurrent( cast(void*)deviceContext, cast(void*)renderContext );
		
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
		//glFrontFace( GL_CW );
		
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

	override void swapBuffers()
	{
		SwapBuffers( deviceContext );
	}

	override void openWindow()
	{
		openWindow( true );
	}

	final void openWindow( bool showWindow )
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
