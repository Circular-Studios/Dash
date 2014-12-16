/**
* TODO
*/
deprecated( "Please use SDL adapter instead." )
module dash.graphics.adapters.win32gl;

version( Windows ):

import dash.core, dash.graphics, dash.utility;

import win32.windef, win32.winuser, win32.winbase;
import win32.wingdi : PIXELFORMATDESCRIPTOR, SetPixelFormat, SwapBuffers;
import derelict.opengl3.gl3, derelict.opengl3.wgl, derelict.opengl3.wglext;

enum DWS_FULLSCREEN = WS_POPUP | WS_SYSMENU;
enum DWS_WINDOWED = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU;

extern( Windows )
private LRESULT WndProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
    switch( message )
    {
        // On close
        case WM_CLOSE:
            DGame.instance.currentState = EngineState.Quit;
            break;
        // If key down, send it to input
        case WM_KEYDOWN:
            Keyboard.setButtonState( cast(Keyboard.Buttons)wParam, true );
            break;
        // If key up, send it to input
        case WM_KEYUP:
            Keyboard.setButtonState( cast(Keyboard.Buttons)wParam, false );
            break;
        // On right mouse down
        case WM_RBUTTONDOWN:
            Mouse.setButtonState( Mouse.Buttons.Right, true );
            break;
        // On right mouse up
        case WM_RBUTTONUP:
            Mouse.setButtonState( Mouse.Buttons.Right, false );
            break;
        // On left mouse down
        case WM_LBUTTONDOWN:
            Mouse.setButtonState( Mouse.Buttons.Left, true );
            break;
        // On left mouse up
        case WM_LBUTTONUP:
            Mouse.setButtonState( Mouse.Buttons.Left, false );
            break;
        // On mouse scroll
        case WM_MOUSEWHEEL:
            Mouse.setAxisState( Mouse.Axes.ScrollWheel, Mouse.getAxisState( Mouse.Axes.ScrollWheel ) + ( HIWORD( wParam ) / WHEEL_DELTA ) );
            break;
            // If no change, send to default windows handler
        // On mouse move
        case WM_MOUSEMOVE:
            Mouse.setAxisState( Mouse.Axes.XPos, LOWORD( wParam ) );
            Mouse.setAxisState( Mouse.Axes.YPos, HIWORD( wParam ) );
            break;

        default:
            return DefWindowProc( hWnd, message, wParam, lParam );
    }
    return 0;
}

/**
* TODO
*/
final class Win32GL : OpenGL
{
private:
    HWND _hWnd;
    HINSTANCE _hInstance;
    bool _wasFullscreen;
    HDC deviceContext;
    HGLRC renderContext;

public:
    /// TODO
    mixin( Property!_hWnd );
    /// TODO
    mixin( Property!_hInstance );
    /// TODO
    static @property Win32GL get() { return cast(Win32GL)Graphics.adapter; }

    /**
    * TODO
    */
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
                cast(void*)hInstance,
                null,
                LoadCursor( null, IDC_ARROW ),
                cast(HBRUSH)( COLOR_WINDOW + 1 ),
                null,
                DGame.instance.title.ptr,
                null
        };

        RegisterClassEx( &wcex );

        // Setup opengl
        uint formatCount;
        int pixelFormat;
        PIXELFORMATDESCRIPTOR pfd;

        // Check for OpenGL version
        openWindow( false );

        deviceContext = GetDC( hWnd );
        SetPixelFormat( deviceContext, 1, &pfd );
        renderContext = wglCreateContext( deviceContext );
        wglMakeCurrent( deviceContext, renderContext );

        DerelictGL3.reload();

        if( DerelictGL3.loadedVersion < GLVersion.GL40 )
        {
            fatalf( "Your version of OpenGL is unsupported. Required: GL40 Yours: %s", DerelictGL3.loadedVersion );
            //throw new Exception( "Unsupported version of OpenGL." );
            return;
        }

        shutdown();
        openWindow();

        // Set attributes list
        const(int)[ 19 ] attributeList = [
            WGL_SUPPORT_OPENGL_ARB, TRUE,                       // Support for OpenGL rendering
            WGL_DRAW_TO_WINDOW_ARB, TRUE,                       // Support for rendering window
            WGL_ACCELERATION_ARB,   WGL_FULL_ACCELERATION_ARB,  // Support for hardware acceleration
            WGL_COLOR_BITS_ARB,     24,                         // Support for 24bit color
            WGL_DEPTH_BITS_ARB,     24,                         // Support for 24bit depth buffer
            WGL_DOUBLE_BUFFER_ARB,  TRUE,                       // Support for double buffer
            WGL_SWAP_METHOD_ARB,    WGL_SWAP_EXCHANGE_ARB,      // Support for swapping buffers
            WGL_PIXEL_TYPE_ARB,     WGL_TYPE_RGBA_ARB,          // Support for RGBA pixel type
            WGL_STENCIL_BITS_ARB,   8,                          // Support for 8 bit stencil buffer
            0                                                   // Null terminate
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

        refresh();

        HANDLE hIcon = LoadImage( null, ( Resources.Textures ~ "/icon.ico" ).ptr, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_LOADFROMFILE);
        if( hIcon )
        {
            //Change both icons to the same icon handle.
            SendMessage( hWnd, WM_SETICON, ICON_SMALL, cast(int)hIcon );
            SendMessage( hWnd, WM_SETICON, ICON_BIG, cast(int)hIcon );

            //This will ensure that the application icon gets changed too.
            SendMessage( GetWindow( hWnd, GW_OWNER ), WM_SETICON, ICON_SMALL, cast(int)hIcon );
            SendMessage( GetWindow( hWnd, GW_OWNER ), WM_SETICON, ICON_BIG, cast(int)hIcon );
        }
    }

    /**
    * TODO
    */
    override void shutdown()
    {
        wglMakeCurrent( null, null );
        wglDeleteContext( renderContext );
        renderContext = null;
        ReleaseDC( hWnd, deviceContext );
        deviceContext = null;
        closeWindow();
    }

    /**
    * TODO
    */
    override void resize()
    {
        LONG style = GetWindowLong( hWnd, GWL_STYLE ) & ~( DWS_FULLSCREEN | DWS_WINDOWED );

        loadProperties();

        if( windowType == WindowType.Fullscreen )
        {
            width = screenWidth;
            height = screenHeight;
            style |= DWS_FULLSCREEN;
        }
        else
        {
            style |= DWS_WINDOWED;
        }

        if( _wasFullscreen != ( windowType == WindowType.Fullscreen ) )
        {
            SetWindowLong( hWnd, GWL_STYLE, style );
            SetWindowPos( hWnd, null, ( screenWidth - width ) / 2, ( screenHeight - height ) / 2,
                          width + ( 2 * GetSystemMetrics( SM_CYBORDER ) ),
                          height + GetSystemMetrics( SM_CYCAPTION ) + GetSystemMetrics( SM_CYBORDER ),
                          SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED );
        }

        _wasFullscreen = ( windowType == WindowType.Fullscreen );

        resizeDefferedRenderBuffer();

        glViewport( 0, 0, width, height );
    }

    /**
    * TODO
    */
    override void refresh()
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

    /**
    * TODO
    */
    override void swapBuffers()
    {
        auto zone = DashProfiler.startZone( "Swap Buffers" );
        SwapBuffers( deviceContext );
    }

    /**
    * TODO
    */
    override void openWindow()
    {
        openWindow( true );
    }

    /**
    * TODO
    */
    final void openWindow( bool showWindow )
    {
        hWnd = CreateWindowEx( 0, DGame.instance.title.ptr, DGame.instance.title.ptr, ( windowType == WindowType.Fullscreen ) ? DWS_FULLSCREEN : DWS_WINDOWED,
                               ( screenWidth - width ) / 2, ( screenHeight - height ) / 2, width, height,
                              null, null, hInstance, null );

        assert( hWnd );

        resize();

        ShowWindow( hWnd, showWindow ? SW_NORMAL : SW_HIDE );
    }

    /**
    * TODO
    */
    override void closeWindow()
    {
        DestroyWindow( hWnd );
        hWnd = null;
    }

    /**
    * TODO
    */
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
