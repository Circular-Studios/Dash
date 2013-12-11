module graphics.windows.win32;
import core.global;
import graphics.graphics, graphics.windows.windows;

import std.c.windows.windows;

// Aliases for win32 types and methods
alias GetModuleHandleA GetModuleHandle;
alias WNDCLASSEXA WNDCLASSEX;
alias MAKEINTRESOURCEA MAKEINTRESOURCE;
alias LoadCursorA LoadCursor;
alias LoadIconA LoadIcon;
alias RegisterClassExA RegisterClassEx;
alias CreateWindowA CreateWindow;
alias PeekMessageA PeekMessage;
alias DispatchMessageA DispatchMessage;

const uint DWS_FULLSCREEN = WS_POPUP | WS_SYSMENU;
const uint DWS_WINDOWED = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU;

version( Windows )
class Win32 : Windows
{
public:
	static @property Win32 get() { return cast(Win32)Graphics.window; }

	mixin( Property!( "HWND", "hWnd" ) );
	mixin( Property!( "HINSTANCE", "hInstance" ) );

	override void initialize()
	{
		//hInstance = GetModuleHandle( null );
		//
		//WNDCLASSEXA wcex;
		//wcex.cbSize				= wcex.sizeof;
		//wcex.style				= CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
		////wcex.lpfnWndProc		= &WndProc;
		//wcex.cbClsExtra			= 0;
		//wcex.cbWndExtra			= 0;
		//wcex.hInstance			= hInstance;
		////wcex.hIcon				= LoadIconA( hInstance, MAKEINTRESOURCE( 
		//wcex.hCursor			= LoadCursor( null, IDC_ARROW );
		//wcex.hbrBackground		= cast(HBRUSH)( COLOR_WINDOW + 1 );
		//wcex.lpszMenuName		= null;
		//wcex.lpszClassName		= "Dvelop";
		////wcex.hIconSm			= LoadIcon( hInstance, IDI_SMALL );
		//
		//RegisterClassEx( &wcex );
	}

	override void shutdown()
	{
		//closeWindow();
	}

	override void resize()
	{
		//long style = GetWindowLong( hWnd, GWL_STYLE ) & ~( DWS_FULLSCREEN | DWS_WINDOWED );
		//
		//screenWidth = GetSystemMetrics( SM_CXSCREEN );
		//screenHeight = GetSystemMetrics( SM_CYSCREEN );
		//
		////fullScreen = Config.GetData!bool( "Display.Fullscreen" );
		//fullscreen = false;
		//
		//if( fullscreen )
		//{
		//    width = screenWidth;
		//    height = screenHeight;
		//    style |= DWS_FULLSCREEN;
		//}
		//else
		//{
		//    width = 1280;//Config.GetData!uint( "Display.Width" );
		//    width = 720;//Config.GetData!uint( "Display.Height" );
		//    style |= DWS_WINDOWED;
		//}
		//
		//SetWindowLong( hWnd, GWL_STYLE, style );
		//SetWindowPos( hWnd, null, ( screenWidth - width ) / 2, ( screenHeight - height ) / 2,
		//              width + ( 2 * GetSystemMetrics( SM_CYBORDER ) ),
		//              height + GetSystemMetrics( SM_CYCAPTION ) + GetSystemMetrics( SM_CYBORDER ),
		//              SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );

		// update matricies
	}

	override void openWindow()
	{
		//resize();
		//
		//hWnd = CreateWindow( "Dvelop", "Dvelop", fullscreen ? DWS_FULLSCREEN : DWS_WINDOWED,
		//                     ( screenWidth - width ) / 2, ( screenHeight - height ) / 2, width, height,
		//                     null, null, hInstance, null );
		//
		//ShowWindow( hWnd, SW_NORMAL );
	}

	override void closeWindow()
	{
		//DestroyWindow( hWnd );
		//hWnd = null;
	}

	override void messageLoop()
	{
	//    MSG msg;
	//
	//    // Initialize the message structure.
	//    ZeroMemory( &msg, msg.sizeof );
	//
	//    // Handle the windows messages.
	//    while( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE ) )
	//    {
	//        TranslateMessage( &msg );
	//        DispatchMessage( &msg );
	//    }
	}
}
