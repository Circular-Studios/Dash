/**
 * Defines the static Input class, which is responsible for handling all keyboard/mouse/controller interactions.
 */
module dash.utility.input.input;
import dash.utility, dash.core, dash.graphics;

import yaml;
import derelict.opengl3.gl3;
import std.conv, std.uuid;

/**
 * Manages all input events.
 */
final abstract class Input
{
static:
private:
    static struct Binding
    {
    public:
        @ignore
        string name;

        @rename( "Keyboard" ) @byName @optional
        Keyboard.Buttons[] keyboardButtons;

        @rename( "Mouse" ) @byName @optional
        Mouse.Buttons[] mouseButtons;

        //@rename( "MouseAxes" ) @optional
        //Mouse.Axes[] mouseAxes;
    }
    Binding[string] bindings;
    Resource bindingFile = Resource( "" );

public:
    /**
     * Processes Config/Input.yml and pulls input string bindings.
     */
    void initialize()
    {
        try
        {
            auto bindingRes = deserializeFileByName!(typeof(bindings))( Resources.InputBindings );
            bindings = bindingRes[ 0 ];
            bindingFile = bindingRes[ 1 ];

            foreach( name, ref binding; bindings )
                binding.name = name;
        }
        catch( Exception e )
        {
            logError( "Error parsing config file:\n", e.toString() );
        }

        Keyboard.initialize();
        Mouse.initialize();
    }

    /**
     * Updates the key states, and calls all key events.
     */
    void update()
    {
        Keyboard.update();
        Mouse.update();
    }

    /**
     * Gets the state of a string-bound input.
     *
     * Params:
     *      input =         The input to check for.
     *      checkPrevious = Whether or not to make sure the key was up last frame.
     */
    T getState( T = bool )( string input, bool checkPrevious = false ) if( is( T == bool ) || is( T == float ) )
    {
        if( auto binding = input in bindings )
        {
            static if( is( T == bool ) )
            {
                foreach( key; binding.keyboardButtons )
                    if( Keyboard.isButtonDown( key, checkPrevious ) )
                        return true;
                foreach( mb; binding.mouseButtons )
                    if( Mouse.isButtonDown( mb, checkPrevious ) )
                        return true;

                return false;
            }
            else static if( is( T == float ) )
            {
                foreach( ma; binding.mouseAxes )
                {
                    auto state = Mouse.getAxisState( ma, checkPrevious );
                    if( state != 0.0f )
                        return state;
                }

                return 0.0f;
            }
        }

        throw new Exception( "Input " ~ input ~ " not bound." );
    }

    /**
     * Check if a given button is down.
     *
     * Params:
     *      buttonName =        The name of the button to check.
     *      checkPrevious =     Whether or not to make sure the button was down last frame.
     */
    bool isButtonDown( string buttonName, bool checkPrevious = false )
    {
        if( auto binding = buttonName in bindings )
        {
            foreach( key; binding.keyboardButtons )
                if( Keyboard.isButtonDown( key, checkPrevious ) )
                    return true;

            foreach( mb; binding.mouseButtons )
                if( Mouse.isButtonDown( mb, checkPrevious ) )
                    return true;
        }

        return false;
    }

    /**
     * Gets the position of the cursor.
     *
     * Returns:     The position of the mouse cursor.
     */
    vec2ui mousePos()
    {
        version( Windows )
        {
            if( !Win32GL.get() )
                return vec2ui();

            import dash.graphics;
            import win32.windows;
            POINT i;
            GetCursorPos( &i );
            ScreenToClient( Win32GL.get().hWnd, &i );

            // Adjust for border
            if( !Graphics.adapter.fullscreen )
            {
                i.x -= GetSystemMetrics( SM_CXBORDER );
                i.y -= GetSystemMetrics( SM_CYBORDER );
            }

            return vec2ui( i.x, Graphics.height - i.y );
        }
        else
        {
            return vec2ui();
        }
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The position of the mouse cursor in world space.
     */
    vec3f mousePosView()
    {
        if( !DGame.instance.activeScene )
        {
            logWarning( "No active scene." );
            return vec3f( 0.0f, 0.0f, 0.0f );
        }

        auto scene = DGame.instance.activeScene;

        if( !scene.camera )
        {
            logWarning( "No camera on active scene." );
            return vec3f( 0.0f, 0.0f, 0.0f );
        }
        vec2ui mouse = mousePos();
        float depth;
        int x = mouse.x;
        int y = mouse.y;
        auto view = vec3f( 0, 0, 0 );

        if( x >= 0 && x <= Graphics.width && y >= 0 && y <= Graphics.height )
        {
            depth = Graphics.getDepthAtScreenPoint( mouse ); 

            auto linearDepth = scene.camera.projectionConstants.x / ( scene.camera.projectionConstants.y - depth );
            //Convert x and y to normalized device coords
            float screenX = ( mouse.x / cast(float)Graphics.width ) * 2 - 1;
            float screenY = -( ( mouse.y / cast(float)Graphics.height ) * 2 - 1 );

            auto viewSpace = scene.camera.inversePerspectiveMatrix * vec4f( screenX, screenY, 1.0f, 1.0f);
            auto viewRay = vec3f( viewSpace.xy * (1.0f / viewSpace.z), 1.0f);
            view = viewRay * linearDepth;
        }

        return view;
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The position of the mouse cursor in world space.
     */
    vec3f mousePosWorld()
    {
        return (DGame.instance.activeScene.camera.inverseViewMatrix * vec4f( mousePosView(), 1.0f )).xyz;
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The GameObject located at the current mouse Position
     */
    GameObject mouseObject()
    {
        if( !DGame.instance.activeScene )
        {
            logWarning( "No active scene." );
            return null;
        }

        auto scene = DGame.instance.activeScene;

        if( !scene.camera )
        {
            logWarning( "No camera on active scene." );
            return null;
        }

        vec2ui mouse = mousePos();

        if( mouse.x >= 0 && mouse.x <= Graphics.width && mouse.y >= 0 && mouse.y <= Graphics.height )
        {
            uint id = Graphics.getObjectIDAtScreenPoint( mouse );

            if( id > 0 )
            {
                return scene[ id ];
            }
        }

        return null;
    }
}

unittest
{
    import std.stdio;
    writeln( "Dash Input isKeyUp unittest" );

    Config.initialize();
    Input.initialize();
    Keyboard.setButtonState( Keyboard.Buttons.Space, true );

    Keyboard.update();
    Keyboard.setButtonState( Keyboard.Buttons.Space, false );

    Keyboard.update();
    assert( Keyboard.isButtonUp( Keyboard.Buttons.Space, true ) );
    assert( Keyboard.isButtonUp( Keyboard.Buttons.Space, false ) );

    Keyboard.update();
    assert( !Keyboard.isButtonUp( Keyboard.Buttons.Space, true ) );
    assert( Keyboard.isButtonUp( Keyboard.Buttons.Space, false ) );
}

unittest
{
    import std.stdio;
    writeln( "Dash Input addKeyEvent unittest" );

    Config.initialize();
    Input.initialize();

    bool keyDown;
    Keyboard.addButtonEvent( Keyboard.Buttons.Space, ( keyCode, newState )
    {
        keyDown = newState;
    } );

    Keyboard.setButtonState( Keyboard.Buttons.Space, true );
    Input.update();
    assert( keyDown );

    Keyboard.setButtonState( Keyboard.Buttons.Space, false );
    Input.update();
    assert( !keyDown );
}

unittest
{
    import std.stdio;
    writeln( "Dash Input isKeyDown unittest" );

    Config.initialize();
    Input.initialize();
    Keyboard.setButtonState( Keyboard.Buttons.Space, true );

    Input.update();
    assert( Keyboard.isButtonDown( Keyboard.Buttons.Space, true ) );
    assert( Keyboard.isButtonDown( Keyboard.Buttons.Space, false ) );

    Input.update();
    assert( !Keyboard.isButtonDown( Keyboard.Buttons.Space, true ) );
    assert( Keyboard.isButtonDown( Keyboard.Buttons.Space, false ) );
}
