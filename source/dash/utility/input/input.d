/**
 * Defines the static Input class, which is responsible for handling all keyboard/mouse/controller interactions.
 */
module dash.utility.input.input;
import dash.utility, dash.core, dash.graphics;

import yaml;
import derelict.opengl3.gl3;
import std.algorithm, std.conv, std.uuid;

/// The event type for button events.
package alias ButtonEvent = void delegate( ButtonStorageType );
/// The event type for axis events.
package alias AxisEvent   = void delegate( AxisStorageType );

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

        @rename( "MouseAxes" ) @byName @optional
        Mouse.Axes[] mouseAxes;
    }

    /// Bindings directly from Config/Input
    Binding[string] bindings;
    /// The file the bindings came from.
    Resource bindingFile = internalResource;

    /// The registered button events.
    Tuple!( UUID, ButtonEvent )[][ string ] buttonEvents;
    /// The registered axis events.
    Tuple!( UUID, AxisEvent )[][ string ] axisEvents;

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
            errorf( "Error parsing config file:%s\n", e.toString() );
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

    /// Called by InputSystem to report changed inputs.
    package void processDiffs( InputSystem, InputEnum, StateRep )( Tuple!( InputEnum, StateRep )[] diffs )
    {
        // Iterate over each diff.
        foreach( diff; diffs )
        {
            // Iterate over each binding.
            foreach( name, binding; bindings )
            {
                // Get the array of bindings to check and events to call.
                static if( is( InputEnum == Keyboard.Buttons ) )
                {
                    auto bindingArray = binding.keyboardButtons;
                    auto eventArray = buttonEvents;
                }
                else static if( is( InputEnum == Mouse.Buttons ) )
                {
                    auto bindingArray = binding.mouseButtons;
                    auto eventArray = buttonEvents;
                }
                else static if( is( InputEnum == Mouse.Axes ) )
                {
                    auto bindingArray = binding.mouseAxes;
                    auto eventArray = axisEvents;
                }
                else static assert( false, "InputEnum unsupported." );

                // Check the binding for the changed input.
                bindingsLoop:
                foreach( button; bindingArray )
                {
                    if( button == diff[ 0 ] && name in eventArray )
                    {
                        foreach( eventTup; eventArray[ name ] )
                        {
                            eventTup[ 1 ]( diff[ 1 ] );
                            break bindingsLoop;
                        }
                    }
                }
            }
        }
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
            else static assert( false, "Unsupported return type." );
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
     * Check if a given button is down.
     *
     * Params:
     *      buttonName =        The name of the button to check.
     *      checkPrevious =     Whether or not to make sure the button was down last frame.
     */
    bool isButtonUp( string buttonName, bool checkPrevious = false )
    {
        if( auto binding = buttonName in bindings )
        {
            foreach( key; binding.keyboardButtons )
                if( Keyboard.isButtonUp( key, checkPrevious ) )
                    return true;

            foreach( mb; binding.mouseButtons )
                if( Mouse.isButtonUp( mb, checkPrevious ) )
                    return true;
        }

        return false;
    }

    /**
     * Add an event for when a button state changes.
     *
     * Params:
     *  buttonName =            The binding name of the button for the event.
     *  event =                 The event to call when the button changes.
     *
     * Returns: The id of the new event.
     */
    UUID addButtonEvent( string buttonName, ButtonEvent event )
    {
        auto id = randomUUID();
        buttonEvents[ buttonName ] ~= tuple( id, event );
        return id;
    }

    /**
     * Add an event for when a button goes down.
     *
     * Params:
     *  buttonName =            The binding name of the button for the event.
     *  event =                 The event to call when the button changes.
     *
     * Returns: The id of the new event.
     */
    UUID addButtonDownEvent( string buttonName, ButtonEvent event )
    {
        return addButtonEvent( buttonName, ( newState ) { if( newState ) event( newState ); } );
    }

    /**
     * Add an event for when a button goes up.
     *
     * Params:
     *  buttonName =            The binding name of the button for the event.
     *  event =                 The event to call when the button changes.
     *
     * Returns: The id of the new event.
     */
    UUID addButtonUpEvent( string buttonName, ButtonEvent event )
    {
        return addButtonEvent( buttonName, ( newState ) { if( !newState ) event( newState ); } );
    }

    /**
     * Add an event for when an axis changes.
     *
     * Params:
     *  axisName =              The binding name of the axis for the event.
     *  event =                 The event to call when the button changes.
     *
     * Returns: The id of the new event.
     */
    UUID addAxisEvent( string axisName, AxisEvent event )
    {
        auto id = randomUUID();
        axisEvents[ axisName ] ~= tuple( id, event );
        return id;
    }

    /**
     * Remove a button event.
     *
     * Params:
     *  buttonName =            The binding name of the button for the event.
     *  event =                 The event to call when the button changes.
     *
     * Returns: The id of the new event.
     */
    bool removeButtonEvent( UUID id )
    {
        foreach( name, ref eventGroup; buttonEvents )
        {
            auto i = eventGroup.countUntil!( tup => tup[ 0 ] == id );

            if( i == -1 )
                continue;

            // Get tasks after one being removed.s
            auto end = eventGroup[ i+1..$ ];
            // Get tasks before one being removed.
            eventGroup = eventGroup[ 0..i ];
            // Add end back.
            eventGroup ~= end;

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
        return vec2ui( cast(uint)Mouse.getAxisState( Mouse.Axes.XPos ),
                       cast(uint)Mouse.getAxisState( Mouse.Axes.YPos ) );
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
            warning( "No active scene." );
            return vec3f( 0.0f, 0.0f, 0.0f );
        }

        auto scene = DGame.instance.activeScene;

        if( !scene.camera )
        {
            warning( "No camera on active scene." );
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
            warning( "No active scene." );
            return null;
        }

        auto scene = DGame.instance.activeScene;

        if( !scene.camera )
        {
            warning( "No camera on active scene." );
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
