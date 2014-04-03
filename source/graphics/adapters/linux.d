module graphics.adapters.linux;

version( linux ):

import core, graphics, utility;

import x11.X, x11.Xlib, x11.Xutil;
import derelict.opengl3.gl3, derelict.opengl3.glx, derelict.opengl3.glxext;

import std.traits;

final class Linux : Adapter
{
public:
    static @property Linux get() { return cast(Linux)Graphics.adapter; }

    override void initialize()
    {
        // Load opengl functions
        DerelictGL3.load();

        int[ 10 ] attrList =
        [
            GLX_RGBA,
            GLX_RED_SIZE, 4,
            GLX_GREEN_SIZE, 4,
            GLX_BLUE_SIZE, 4,
            GLX_DEPTH_SIZE, 16,
            None
        ];

        int screen;

        // Get display and screen
        display = XOpenDisplay( null );
        screen = DefaultScreen( display );
        
        // Setup the window
        screenWidth = DisplayWidth( display, screen );
        screenHeight = DisplayHeight( display, screen );

        loadProperties();

        if( display is null )
        {
            logError( "Cannot connect to X server." );
            return;
        }

        // Get root monitor window
        root = DefaultRootWindow( display );

        // Chose visual based on attributes and display
        glvi = glXChooseVisual( display, 0, attrList.ptr );
        xvi = cast(XVisualInfo*)glvi;

        if( xvi is null )
        {
            logError( "No appropriate visual found." );
            return;
        }

        cmap = XCreateColormap( display, root, xvi.visual, AllocNone );

        // Set attributes for window
        windowAttributes.colormap = cmap;
        windowAttributes.event_mask = EventMask;

        openWindow();

        // Get address of gl functions
        DerelictGL3.reload();
    }
    
    override void shutdown()
    {
        closeWindow();
        XCloseDisplay( display );
    }
    
    override void resize()
    {
        XResizeWindow( display, window, width, height );
        glViewport( 0, 0, width, height );
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
        glXSwapIntervalEXT( display, glXGetCurrentDrawable(), vsync );
    }
    
    override void swapBuffers()
    {
        glXSwapBuffers( display, cast(uint)window );
    }
    
    override void openWindow()
    {
        window = XCreateWindow(
            display, root,
            0, 0, width, height, 0, 
            xvi.depth, InputOutput, xvi.visual,
            CWColormap | CWEventMask, &windowAttributes );
        
        XMapWindow( display, window );
        XStoreName( display, window, DGame.instance.title.dup.ptr );
        
        context = glXCreateContext( display, glvi, null, GL_TRUE );
        glXMakeCurrent( display, cast(uint)window, context );
    }

    override void closeWindow()
    {
        glXMakeCurrent( display, None, null );
        glXDestroyContext( display, context );
        XDestroyWindow( display, window );
    }
    
    override void messageLoop()
    {
        XEvent event;
        while( XCheckWindowEvent( display, window, EventMask, &event ) )
        {
            switch( event.type )
            {
                case KeyPress:
                    break;
                case Expose:
                    break;
                default:
                    break;
            }
        }
    }

private:
    // Because the XVisualStyle type returned from this function is
    // seemingly not defined, we can get it with templates.
    alias PointerTarget!(ReturnType!(glXChooseVisual)) GLXVisualInfo;

    /// Events we want to listen for
    enum EventMask = ExposureMask | KeyPressMask;

    /// The display to render to.
    Display* display;
    ///
    Window root;
    Window window;
    GLXContext context;
    XSetWindowAttributes windowAttributes;
    XVisualInfo* xvi;
    GLXVisualInfo* glvi;
    Colormap cmap;
} 
