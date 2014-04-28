/**
 * Handles the creation and life cycle of UI objects and webview textures
 */
module components.userinterface;
import core;
import utility.awesomium, components, utility, graphics.graphics;
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
    AwesomiumView _view;
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
        _view = new shared AwesomiumView( w, h, filePath, null );
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

    /**
     * Initializes Awesomium singleton
     */
    static void initializeAwesomium()
    {
        version( Windows )
        {
            // Webcore setup
            awe_webcore_initialize_default();
            string baseDir = FilePath.Resources.UI;
            awe_string* aweBaseDir = awe_string_create_from_ascii( baseDir.toStringz(), baseDir.length );
            awe_webcore_set_base_directory( aweBaseDir );
            awe_string_destroy( aweBaseDir );
        }
    }

    /**
     * Updates Awesomium singleton
     */
    static void updateAwesomium()
    {
        version( Windows )
        awe_webcore_update();
    }

    /**
     * Shutdowns Awesomium singleton
     */
    static void shutdownAwesomium()
    {
        version( Windows )
        awe_webcore_shutdown();
    }
}


/**
 * Creates an Awesomium web view texture
 */
shared class AwesomiumView : Texture, IComponent
{
private:
    version( Windows )
    awe_webview* webView;
    ubyte[] glBuffer;

public:
    this( uint w, uint h, string filePath, shared GameObject owner, bool localFilePath = true )
    {
        _width = w;
        _height = h;
        glBuffer = new ubyte[_width*_height*4];
        this.owner = owner;

        super( cast(ubyte*)null );

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
        }
    }

    override void update()
    {
        // No webview? No update.
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
    }

    override void shutdown()
    {
        destroy( glBuffer );
        version( Windows ) 
        awe_webview_destroy( cast(awe_webview*)webView );
    }
}
