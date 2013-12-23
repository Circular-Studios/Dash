module graphics.windows.win32;

version( Windows ):

import core.properties;
import graphics.graphics;
import graphics.windows.windows;
import graphics.adapters.opengl;

import win32.windef, win32.winuser, win32.winbase;

const uint DWS_FULLSCREEN = WS_POPUP | WS_SYSMENU;
const uint DWS_WINDOWED = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU;

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
			//Input.keyDown( (unsigned int)wParam );
			break;
			// If key up, send it to input
        case WM_KEYUP:
			//Input.keyUp( (unsigned int)wParam );
			break;
			// On Mouse Event
        case WM_RBUTTONDOWN:
			//Input.keyDown( VK_RBUTTON );
			break;
			// On Mouse Event
        case WM_RBUTTONUP:
			//Input.keyUp( VK_RBUTTON );
			break;
			// On Mouse Event
        case WM_LBUTTONDOWN:
			//Input.keyDown( VK_LBUTTON );
			break;
			// On Mouse Event
        case WM_LBUTTONUP:
			//Input.keyUp( VK_LBUTTON );
			break;
			// If no change, send to default windows handler
        default:
			return DefWindowProc( hWnd, message, wParam, lParam );
	}
	return 0;
}

class Win32 : Windows
{
public:
	static @property Win32 get() { return cast(Win32)Graphics.window; }

	override @property OpenGL gl()
	{
		static Win32Gl opengl;
		if( opengl is null )
			opengl = new Win32Gl;

		return opengl;
	}

	mixin( Property!( "HWND", "hWnd" ) );
	mixin( Property!( "HINSTANCE", "hInstance" ) );

	override void initialize()
	{
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
			"Dvelop",
			null
		};

		RegisterClassEx( &wcex );
	}

	override void shutdown()
	{
		closeWindow();
	}

	override void resize()
	{
		LONG style = GetWindowLong( hWnd, GWL_STYLE ) & ~( DWS_FULLSCREEN | DWS_WINDOWED );

		screenWidth = GetSystemMetrics( SM_CXSCREEN );
		screenHeight = GetSystemMetrics( SM_CYSCREEN );

		//fullScreen = Config.GetData!bool( "Display.Fullscreen" );
		fullscreen = false;

		if( fullscreen )
		{
			width = screenWidth;
			height = screenHeight;
			style |= DWS_FULLSCREEN;
		}
		else
		{
			width = 1280;//Config.GetData!uint( "Display.Width" );
			height = 720;//Config.GetData!uint( "Display.Height" );
			style |= DWS_WINDOWED;
		}

		SetWindowLong( hWnd, GWL_STYLE, style );
		SetWindowPos( hWnd, null, ( screenWidth - width ) / 2, ( screenHeight - height ) / 2,
					  width + ( 2 * GetSystemMetrics( SM_CYBORDER ) ),
					  height + GetSystemMetrics( SM_CYCAPTION ) + GetSystemMetrics( SM_CYBORDER ),
					  SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );

		// update matricies
	}

	override void openWindow()
	{
		resize();

		hWnd = CreateWindowEx( 0, "Dvelop", "Dvelop", fullscreen ? DWS_FULLSCREEN : DWS_WINDOWED,
							 ( screenWidth - width ) / 2, ( screenHeight - height ) / 2, width, height,
							 null, null, hInstance, null );

		assert( hWnd );

		ShowWindow( hWnd, SW_NORMAL );
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
