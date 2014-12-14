/**
 * Handles the creation and life cycle of UI objects and webview textures
 */
module dash.components.userinterface;
import dash, dash.utility.bindings.awesomium;

import std.string;

version( Windows )
{
    private awe_string* dToAwe( string str )
    {
        return awe_string_create_from_ascii( str.ptr, str.length );
    }

    private string aweToD( const(awe_string)* str )
    {
        string dStr = new string( awe_string_get_length( str ) );
        awe_string_to_utf8( str, (cast(char[])dStr).ptr, dStr.length );
        return dStr;
    }
}

/**
 * User interface objects handle drawing/updating an AwesomiumView over the screen
 */
class UserInterface
{
private:
    uint _height;
    uint _width;
    mat4f _scaleMat;
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
        _scaleMat = mat4f.identity;
        _scaleMat[0][0] = cast(float)w/2.0f;
        _scaleMat[1][1] = cast(float)h/2.0f;
        _height = h;
        _width = w;
        version(Windows)
        {
            _view = new AwesomiumView( w, h, filePath, null );
        }
        tracef( "UI File: %s", filePath );
    }

    /**
     * Update UI view
     */
    void update()
    {
        /// TODO: Check for mouse & keyboard input
        version(Windows)
        {
            // Send mouse pos to awesomium
            auto mousePos = Input.mousePos();
            awe_webview_inject_mouse_move( _view.webView, cast(int)mousePos.x,cast(int)( Graphics.height - mousePos.y ) );

			auto mouseUp = Mouse.isButtonUp(Mouse.Buttons.Left, true);
			if( mouseUp ) awe_webview_inject_mouse_up( _view.webView, awe_mousebutton.AWE_MB_LEFT );

            _view.update();
        }
    }

    /**
     * Cleanup UI memory
     */
    void shutdown()
    {
        version(Windows)
        // Try to clean up gl buffers
        _view.shutdown();
        // Clean up mesh, material, and view
    }

    /*
     * Call a JS Function on this UI
     *
     * Params:
     *  funcName =          Name of the function to call
     *  args =              Array of integer args to send to the function
     *  object =            Name of the js object containing the function. Blank for global function.
     */
    void callJSFunction( string funcName, int[] args, string object = "" )
    {
        version(Windows)
        {
            // Convert params to awe_js objects
            awe_string* funcStr = awe_string_create_from_ascii( funcName.toStringz(), funcName.length );
            awe_string* objectStr = awe_string_create_from_ascii( object.toStringz(), object.length );
            awe_string* frameStr = awe_string_create_from_ascii( "".toStringz(), 1 );

            // Build array of js ints
            awe_jsvalue*[] jsArgs = new awe_jsvalue*[ args.length ];

            for( int i = 0; i < args.length; i++ )
            {
                jsArgs[i] = awe_jsvalue_create_integer_value( args[i] );
            }

            awe_jsarray* argArr = awe_jsarray_create( jsArgs.ptr, args.length );



            // Execute call
            awe_webview_call_javascript_function( _view.webView, objectStr, funcStr, argArr, frameStr );


            // Clean up js objects
            for( int i = 0; i < args.length; i++ )
            {
                awe_jsvalue_destroy( jsArgs[i] );
            }
            awe_jsarray_destroy( argArr );
        }

    }

    /**
     * Initializes Awesomium singleton
     */
    static void initializeAwesomium()
    {
        version( Windows )
        {
            // Webcore setup
            awe_webcore_initialize_default();
            string baseDir = Resources.UI;
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
class AwesomiumView : TextureAsset
{
private:
    version( Windows )
    const(awe_renderbuffer)* renderBuffer;

public:
//package(dash):
    version( Windows )
    awe_webview* webView;
    ubyte[] glBuffer;

    this( uint w, uint h, string filePath, GameObject owner, bool localFilePath = true )
    {
        _width = w;
        _height = h;
        glBuffer = new ubyte[_width*_height*4];

        super( cast(ubyte*)null, internalResource );

        version( Windows )
        {
            webView = awe_webcore_create_webview( _width, _height, false );
            webView.awe_webview_set_transparent( true );
            awe_string* urlString = awe_string_create_from_ascii( filePath.toStringz(), filePath.length );

            if ( localFilePath )
                webView.awe_webview_load_file( urlString,
                                       awe_string_empty());
            else
                webView.awe_webview_load_url( urlString,
                                      awe_string_empty(),
                                      awe_string_empty(),
                                      awe_string_empty());

            // Wait for WebView to finish loading the page
            // JK DON'T
            //while(awe_webview_is_loading_page(cast(awe_webview*)webView))
                //awe_webcore_update();

            // Destroy our URL string
            urlString.awe_string_destroy();

            awe_webview_set_callback_js_callback( webView, &jsCallbackHandler );

            awe_webview_create_object( webView, dToAwe( "dash" ) );
            awe_webview_set_object_callback( webView, dToAwe( "dash" ), dToAwe( "callFunction" ) );

            awe_webview_set_callback_js_console_message( webView, ( caller, message, line_number, source ) {
                infof( "JS message (%s:%d): %s", source.aweToD(), line_number, message.aweToD() );
            } );
        }
    }

    override void update()
    {
        // No webview? No update.
        version( Windows )
        if ( webView && webView.awe_webview_is_dirty() )
        {
            renderBuffer = webView.awe_webview_render();

            // Ensure the buffer exists
            if ( renderBuffer !is null ) {

                renderBuffer.awe_renderbuffer_copy_to( glBuffer.ptr, awe_renderbuffer_get_rowspan( renderBuffer ), 4, false, true );

                updateBuffer( glBuffer.ptr );
            }

        }
    }

    override void shutdown()
    {
        destroy( glBuffer );
        version( Windows )
        webView.awe_webview_destroy();
    }

    void registerCallback( Args... )( string name, void delegate( Args ) cb )
    {
        void jsHandler( const(awe_jsarray)* jsargs )
        {
            import std.typecons;
            Tuple!Args convertedArgs;

            foreach( i, ArgT; Args )
            {
                auto jsarg = jsargs.awe_jsarray_get_element( i + 1 );

                static if( is( ArgT == string ) )
                {
                    convertedArgs[ i ] = jsarg.awe_jsvalue_to_string().aweToD();
                }
                else static if( is( ArgT == int ) )
                {
                    convertedArgs[ i ] = jsarg.awe_jsvalue_to_integer();
                }
                else static if( is( ArgT == double ) )
                {
                    convertedArgs[ i ] = jsarg.awe_jsvalue_to_double();
                }
                else static if( is( ArgT == bool ) )
                {
                    convertedArgs[ i ] = jsarg.awe_jsvalue_to_bool();
                }
                else static assert( false, "Unsupported type " ~ __traits(identifier, ArgT) ~ ". Please use string, int, double, or bool." );
            }

            cb( convertedArgs.expand );
        }

        handlers[ name ] = &jsHandler;
    }

private:
    version( Windows )
    static void delegate( const(awe_jsarray)* args )[string] handlers;

    version( Windows )
    extern(C)
    static void jsCallbackHandler( awe_webview* caller,
                                   const(awe_string)* object_name,
                                   const(awe_string)* callback_name,
                                   const(awe_jsarray)* arguments )
    {
        assert( awe_jsarray_get_size( arguments ) > 0, "Must at least pass function name." );

        // Get the name of the function to call
        auto funcName = awe_jsarray_get_element( arguments, 0 );
        assert( awe_jsvalue_get_type( funcName ) == awe_jsvalue_type.JSVALUE_TYPE_STRING, "First argument should be function name." );

        // Convert the name to a D string
        auto funcNameStr = awe_jsvalue_to_string( funcName ).aweToD();

        // Call the handler
        handlers[ funcNameStr ]( arguments );
    }
}
