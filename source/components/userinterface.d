/**
 * Handles the creation and life cycle of UI objects and webview textures
 */
module components.userinterface;
import core;
import deimos.cef3.app, components, utility, graphics.graphics;
import std.string, gl3n.linalg;

/**
 * User interface objects handle drawing/updating an AwesomiumView over the screen 
 */
shared class UserInterface
{
private:
    uint _height;
    uint _width;
    shared mat4 _scaleMat;
    WebView _view;

    // TODO: Handle JS

public:
    /// WebView to be drawn
    mixin( Property!(_view, AccessModifier.Public) );
    /// Scale of the UI
    mixin( Property!(_scaleMat, AccessModifier.Public) );

    /**
     * Create UI object
     *
     * Params:
     *  w =         Width (in pixels) of UI
     *  h =         Height (in pixels) of UI
     *  filePath =  Absolute file path to UI file
     */
    this( uint w, uint h, string filePath ) 
    {
        _scaleMat = mat4.identity;
        _scaleMat[0][0] = cast(float)w/2.0f;
        _scaleMat[1][1] = cast(float)h/2.0f;
        _height = h;
        _width = w;
        _view = new shared WebView( w, h, filePath, null );
        logDebug( "UI File: ", filePath );
    }

    /**
     * Update UI view
     */
    void update()
    {
        /// TODO: Check for mouse & keyboard input

        _view.update();

        return;
    }

    /**
     * Draw UI view
     */
    void draw()
    {
        Graphics.addUI( this );
    }

    /**
     * Cleanup UI memory
     */
    void shutdown()
    {
        // Try to clean up gl buffers
        _view.shutdown();
        // Clean up mesh, material, and view
    }

    /*
    void keyPress(int key)
    {

    }
    */

    static void initializeCEF()
    {

        cef_main_args_t mainArgs = {};
        mainArgs.instance = GetModuleHandle(NULL);
        
        // Application handler and its callbacks.
        // cef_app_t structure must be filled. It must implement
        // reference counting. You cannot pass a structure 
        // initialized with zeroes.
        cef_app_t app = {};

        //printf("initialize_app_handler\n");
        app.base.size = cef_app_t.sizeof;

        //printf("initialize_cef_base\n");
        // Check if "size" member was set.
        size_t size = app.base.size;
        // Let's print the size in case sizeof was used
        // on a pointer instead of a structure. In such
        // case the number will be very high.
        //printf("cef_base_t.size = %lu\n", cast(ulong)size);
        if (size <= 0) {
            //printf("FATAL: initialize_cef_base failed, size member not set\n");
            stop();
        }
        


        // Execute subprocesses.
        //printf("cef_execute_process, argc=%d\n", argc);
        int code = cef_execute_process(&mainArgs, &app, NULL);
        if (code >= 0) {
            stop();
        }
        
        // Application settings.
        // It is mandatory to set the "size" member.
        cef_settings_t settings = {};
        settings.size = cef_settings_t.sizeof;
        settings.no_sandbox = 1;
        settings.windowless_rendering_enabled = 1;
        //settings.multi_threaded_message_loop = 0;


        // Initialize CEF.
        //printf("cef_initialize\n");
        cef_initialize(&mainArgs, &settings, &app, NULL);


        version( Windows )
        {



            //_cef_main_args_t mainArgs = {};

            // Webcore setup
            /*
            awe_webcore_initialize_default();
            string baseDir = FilePath.Resources.UI;
            awe_string* aweBaseDir = awe_string_create_from_ascii( baseDir.toStringz(), baseDir.length );
            awe_webcore_set_base_directory( aweBaseDir );
            awe_string_destroy( aweBaseDir );
            */
        }
    }

    static void updateCEF()
    {
        cef_do_message_loop_work(); 
        //version( Windows )
        //awe_webcore_update();
    }

    static void shutdownCEF()
    {
        logDebug("Shutdown CEF");
        cef_quit_message_loop();
        cef_shutdown();

        //version( Windows )
        //awe_webcore_shutdown();
    }
}

shared class RenderHandler
{
private:
    wwwwwwwww
public:

}

shared class WebView : Texture, IComponent
{
private:
    //version( Windows )
    //awe_webview* webView;
    ubyte[] glBuffer;

public:
    this( uint w, uint h, string filePath, shared GameObject owner, bool localFilePath = true )
    {
        _width = w;
        _height = h;
        glBuffer = new ubyte[_width*_height*4];
        this.owner = owner;

        super( cast(ubyte*)null );
        /*
        version( Windows )
        {
            webView = cast(shared)awe_webcore_create_webview( _width, _height, false );
            awe_webview_set_transparent( cast(awe_webview*)webView, true );
            awe_string* urlString = awe_string_create_from_ascii( filePath.toStringz(), filePath.length );

            if ( localFilePath )
                awe_webview_load_file(cast(awe_webview*)webView,
                                        urlString,
                                        awe_string_empty());
            else 
                awe_webview_load_url(cast(awe_webview*)webView,
                                        urlString,
                                        awe_string_empty(),
                                        awe_string_empty(),
                                        awe_string_empty());

            // Wait for WebView to finish loading the page
            // JK DON'T
            //while(awe_webview_is_loading_page(cast(awe_webview*)webView))
                //awe_webcore_update();
        
            // Destroy our URL string
            awe_string_destroy( urlString );
        }*/
    }

    override void update()
    {
        // No webview? No update.
        /*
        version( Windows )
        if ( webView && awe_webview_is_dirty( cast(awe_webview*)webView ) )
        {
            const(awe_renderbuffer)* buffer = awe_webview_render( cast(awe_webview*)webView );

            // Ensure the buffer exists
            if ( buffer !is null ) {

                buffer.awe_renderbuffer_copy_to( cast(ubyte*)glBuffer.ptr, awe_renderbuffer_get_rowspan( buffer ), 4, false, true );

                updateBuffer( cast(ubyte*)glBuffer.ptr );
            }

        }
        */
    }

    override void shutdown()
    {
        //version( Windows ) 
        //awe_webview_destroy( cast(awe_webview*)webView );
    }
}


void initializeCefBase( cef_base_t* base )
{
    assert( base.size > 0 );

    base.add_ref = ( cef_base_t* self ) { return 1; };
    base.release = ( cef_base_t* self ) { return 1; };
    base.get_refct = ( cef_base_t* self ) { return 1; };
}

void initializeCefClient( cef_client_t* client )
{
    client.base.size = cef_client_t.sizeof;
    initializeCefBase( cast( cef_client_t* )client );


}

void initializeCefRenderHandler( cef_render_handler_t* renderHandler )
{
    renderHandler.get_root_screen_rect = ( cef_render_handler_t* self, cef_browser_t* browser, cef_rect_t* rect )
    {
        rect.x = 0;
        rect.y = 0;
        rect.width = Graphics.width;
        rect.height = Graphics.height;

        //rect = CefRect(0, 0, m_renderTexture->getWidth(), m_renderTexture->getHeight());
        return true;
        
    };

    renderHandler.on_paint = ( cef_render_handler_t* self, cef_browser_t* browser, cef_paint_element_type_t type, size_t dirtyRectsCount, const(cef_rect_t)* dirtyRects, const(void)* buffer, int width, int height)
    {
        /*
        Ogre::HardwarePixelBufferSharedPtr texBuf = m_renderTexture->getBuffer();
        texBuf->lock(Ogre::HardwareBuffer::HBL_DISCARD);
        memcpy(texBuf->getCurrentLock().data, buffer, width*height*4);
        texBuf->unlock();
        */
    };

    /*
    ///
    // Called to retrieve the root window rectangle in screen coordinates. Return
    // true (1) if the rectangle was provided.
    ///
    extern(System) int function(    cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    cef_rect_t* rect) get_root_screen_rect;

    ///
    // Called to retrieve the view rectangle which is relative to screen
    // coordinates. Return true (1) if the rectangle was provided.
    ///
    extern(System) int function(    cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    cef_rect_t* rect) get_view_rect;

    ///
    // Called to retrieve the translation from view coordinates to actual screen
    // coordinates. Return true (1) if the screen coordinates were provided.
    ///
    extern(System) int function(    cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    int viewX,
                                    int viewY,
                                    int* screenX,
                                    int* screenY) get_screen_point;

    ///
    // Called to allow the client to fill in the CefScreenInfo object with
    // appropriate values. Return true (1) if the |screen_info| structure has been
    // modified.
    //
    // If the screen info rectangle is left NULL the rectangle from GetViewRect
    // will be used. If the rectangle is still NULL or invalid popups may not be
    // drawn correctly.
    ///
    extern(System) int function(    cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    cef_screen_info_t* screen_info) get_screen_info;

    ///
    // Called when the browser wants to show or hide the popup widget. The popup
    // should be shown if |show| is true (1) and hidden if |show| is false (0).
    ///
    extern(System) void function(   cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    int show) on_popup_show;

    ///
    // Called when the browser wants to move or resize the popup widget. |rect|
    // contains the new location and size.
    ///
    extern(System) void function(   cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    const(cef_rect_t)* rect) on_popup_size;

    ///
    // Called when an element should be painted. |type| indicates whether the
    // element is the view or the popup widget. |buffer| contains the pixel data
    // for the whole image. |dirtyRects| contains the set of rectangles that need
    // to be repainted. On Windows |buffer| will be |width|*|height|*4 bytes in
    // size and represents a BGRA image with an upper-left origin.
    ///
    extern(System) void function(   cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    cef_paint_element_type_t type,
                                    size_t dirtyRectsCount,
                                    const(cef_rect_t)* dirtyRects,
                                    const(void)* buffer,
                                    int width,
                                    int height) on_paint;

    ///
    // Called when the browser window's cursor has changed.
    ///
    extern(System) void function(   cef_render_handler_t* self,
                                    cef_browser_t* browser,
                                    cef_cursor_handle_t cursor) on_cursor_change;

    ///
    // Called when the scroll offset has changed.
    ///
    extern(System) void function(   cef_render_handler_t* self,
                                    cef_browser_t* browser) on_scroll_offset_changed;
    */
}