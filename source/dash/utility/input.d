/**
 * Defines the static Input class, which is responsible for handling all keyboard/mouse/controller interactions.
 */
module dash.utility.input;
import dash.utility, dash.core, dash.graphics;

import yaml, gl3n.linalg;
import derelict.opengl3.gl3;
import std.typecons, std.conv, std.traits, std.uuid;

/**
 * Manages all input events.
 */
final abstract class Input
{
static:
private:
    struct Binding
    {
    public:
        string name;
        Keyboard.Buttons[] KeyboardButtons;
        Mouse.Buttons[] MouseButtons;
        //Mouse.Axes[] MouseAxes;

        this( string bind )
        {
            name = bind;
        }
    }
    Binding[string] inputBindings;

    enum passThrough( string functionName, string args ) = q{
        void $functionName( string inputName, void delegate( $args ) func )
        {
            if( auto binding = inputName in inputBindings )
            {
                foreach( key; binding.KeyboardButtons )
                    Keyboard.$functionName( key, cast(ParameterTypeTuple!(__traits(getMember, Keyboard, "$functionName"))[ 1 ])func );

                foreach( mb; binding.MouseButtons )
                    Mouse.$functionName( mb, cast(ParameterTypeTuple!(__traits(getMember, Mouse, "$functionName"))[ 1 ])func );
            }
            else
            {
                throw new Exception( "Name " ~ inputName ~ " not bound." );
            }
        }
    }.replaceMap( [ "$functionName": functionName, "$args": args ] );
public:
    /**
     * Processes Config/Input.yml and pulls input string bindings.
     */
    void initialize()
    {
        auto bindings = Resources.InputBindings.loadYamlFile();

        Keyboard.initialize();
        Mouse.initialize();

        foreach( string name, Node bind; bindings )
        {
            if( !bind.isMapping )
            {
                logWarning( "Unsupported input format for ", name, "." );
                continue;
            }

            inputBindings[ name ] = Binding( name );

            foreach( string type, Node value; bind )
            {
                enum parseType( string type ) = q{
                    case "$type":
                        if( value.isScalar )
                        {
                            try
                            {
                                inputBindings[ name ].$typeButtons ~= value.get!string.to!($type.Buttons);
                            }
                            catch( Exception e )
                            {
                                logFatal( "Failed to parse keybinding for input ", name, ": ", e.msg );
                            }
                        }
                        else if( value.isSequence )
                        {
                            foreach( Node element; value )
                            {
                                try
                                {
                                    inputBindings[ name ].$typeButtons ~= element.get!string.to!($type.Buttons);
                                }
                                catch( Exception e )
                                {
                                    logFatal( "Failed to parse keybinding for input ", name, ": ", e.msg );
                                }
                            }
                        }
                        else
                        {
                            logFatal( "Failed to parse $type binding for input ", name, ": Mappings not allowed." );
                        }
                        break;
                }.replaceMap( [ "$type": type ] );

                final switch( type )
                {
                    mixin( parseType!q{Keyboard} );
                    mixin( parseType!q{Mouse} );
                }
            }
        }
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
        static if( is( T == bool ) )
        {
            if( auto binding = input in inputBindings )
            {
                foreach( key; binding.KeyboardButtons )
                    if( Keyboard.isButtonDown( key, checkPrevious ) )
                        return true;
                foreach( mb; binding.MouseButtons )
                    if( Mouse.isButtonDown( mb, checkPrevious ) )
                        return true;

                return false;
            }
        }
        /*else static if( is( T == float ) )
        {
            if( input in Keyboard.axisBindings )
            {
                return Keyboard.getAxisState( input );
            }
            else if( input in Mouse.axisBindings )
            {
                return Mouse.getAxisState( input );
            }
        }*/

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
        if( auto binding = buttonName in inputBindings )
        {
            foreach( key; binding.KeyboardButtons )
                if( Keyboard.isButtonDown( key, checkPrevious ) )
                    return true;

            foreach( mb; binding.MouseButtons )
                if( Mouse.isButtonDown( mb, checkPrevious ) )
                    return true;
        }

        return false;
    }

    /**
     * Add an event to be fired when the given button changes.
     *
     * Params:
     *      inputName =     The name of the input to add the event to.
     *      func =          The function to call when the button state changes.
     */
    mixin( passThrough!( "addButtonEvent", "uint, bool" ) );

    /**
     * Add a button event only when the button is down.
     */
    mixin( passThrough!( "addButtonDownEvent", "uint" ) );

    /**
     * Add a button event only when the button is up.
     */
    mixin( passThrough!( "addButtonUpEvent", "uint" ) );

    /**
     * Gets the position of the cursor.
     *
     * Returns:     The position of the mouse cursor.
     */
    vec2i mousePos()
    {
        version( Windows )
        {
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

            return vec2i( i.x, Graphics.height - i.y );
        }
        else
        {
            return vec2i();
        }
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The position of the mouse cursor in world space.
     */
    vec3 mousePosView()
    {
        if( !DGame.instance.activeScene )
        {
            logWarning( "No active scene." );
            return vec3( 0.0f, 0.0f, 0.0f );
        }

        auto scene = DGame.instance.activeScene;

        if( !scene.camera )
        {
            logWarning( "No camera on active scene." );
            return vec3( 0.0f, 0.0f, 0.0f );
        }
        vec2i mouse = mousePos();
        float depth;
        int x = mouse.x;
        int y = mouse.y;
        auto view = vec3( 0, 0, 0 );

        if( x >= 0 && x <= Graphics.width && y >= 0 && y <= Graphics.height )
        {
            depth = Graphics.getDepthAtScreenPoint( mouse ); 

            auto linearDepth = scene.camera.projectionConstants.x / ( scene.camera.projectionConstants.y - depth );
            //Convert x and y to normalized device coords
            float screenX = ( mouse.x / cast(float)Graphics.width ) * 2 - 1;
            float screenY = -( ( mouse.y / cast(float)Graphics.height ) * 2 - 1 );

            auto viewSpace = scene.camera.inversePerspectiveMatrix * vec4( screenX, screenY, 1.0f, 1.0f);
            auto viewRay = vec3( viewSpace.xy * (1.0f / viewSpace.z), 1.0f);
            view = viewRay * linearDepth;
        }

        return view;
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The position of the mouse cursor in world space.
     */
    vec3 mousePosWorld()
    {
        return (DGame.instance.activeScene.camera.inverseViewMatrix * vec4( mousePosView(), 1.0f )).xyz;
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

        vec2i mouse = mousePos();

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

alias Keyboard  = InputSystem!( KeyboardButtons, void );
alias Mouse     = InputSystem!( MouseButtons, MouseAxes );

private:
/**
 * Defines a system of inputs, buttons, axes or both.
 *
 * Params:
 *  ButtonEnum =        The enum of buttons for this system.
 *  AxisEnum =          The enum of axes for this system.
 */
final abstract class InputSystem( ButtonEnum, AxisEnum )
{
static:
public:
    /// Whether or not the system has buttons.
    enum HasButtons = !is( ButtonEnum == void );
    /// Whether or not the system has axes.
    enum HasAxes    = !is( AxisEnum == void );

private:
    /**
     * Initialize all states and events.
     */
    void initialize()
    {
        static if( HasButtons )
        {
            buttonCurrent.reset();
            buttonPrevious.reset();
            buttonStaging.reset();

            foreach( key; buttonEvents.keys )
                buttonEvents.remove( key );
        }
        static if( HasAxes )
        {
            axisCurrent.reset();
            axisStaging.reset();

            foreach( key; axisEvents.keys )
                axisEvents.remove( key );
        }
    }

    /**
     * Update all events and states.
     */
    void update()
    {
        static if( HasButtons )
        {
            auto diffButtons = buttonStaging - buttonCurrent;
            buttonPrevious = buttonCurrent;
            buttonCurrent = buttonStaging;

            foreach( state; diffButtons )
                if( auto buttonEvent = state[ 0 ] in buttonEvents )
                    foreach( event; *buttonEvent )
                        event( state[ 0 ], state[ 1 ] );
        }
        static if( HasAxes )
        {
            auto diffAxis = axisStaging - axisCurrent;
            axisCurrent = axisStaging;

            foreach( state; diffAxis )
                if( auto axisEvent = state[ 0 ] in axisEvents )
                    foreach( event; *axisEvent )
                        event( state[ 0 ], state[ 1 ] );
        }
    }

// If we have buttons
static if( HasButtons )
{
public:
    /// The enum of buttons that the input system has.
    alias Buttons           = ButtonState.Inputs;
    /// The type each button is stored as.
    alias ButtonStorageType = bool;
    /// A delegate that takes the changed button and the new state.
    alias ButtonEvent       = void delegate( Buttons, ButtonStorageType );
    /// A delegate that takes the changed button.
    alias ButtonStateEvent  = void delegate( Buttons );

    /**
     * Check if a given button is down.
     *
     * Params:
     *  buttonCode =        The button to check.
     *  checkPrevious =     Whether or not to make sure the button was down last frame.
     *
     * Returns: The state of the button.
     */
    ButtonStorageType getButtonState( Buttons buttonCode )
    {
        return buttonCurrent[ buttonCode ];
    }

    /**
     * Check if a given button is down.
     *
     * Params:
     *  buttonCode =        The code of the button to check.
     *  checkPrevious =     Whether or not to make sure the button was down last frame.
     *
     * Returns: The state of the button.
     */
    ButtonStorageType isButtonDown( Buttons buttonCode, bool checkPrevious = false )
    {
        return buttonCurrent[ buttonCode ] && ( !checkPrevious || !buttonPrevious[ buttonCode ] );
    }

    /**
     * Check if a given button is up.
     *
     * Params:
     *      buttonCode =        The code of the button to check.
     *      checkPrevious =     Whether or not to make sure the button was up last frame.
     *
     * Returns: The state of the button.
     */
    ButtonStorageType isButtonUp( Buttons buttonCode, bool checkPrevious = false )
    {
        return !buttonCurrent[ buttonCode ] && ( !checkPrevious || buttonPrevious[ buttonCode ] );
    }

    /**
     * Add an event to be fired when the given button changes.
     *
     * Params:
     *      buttonCode =    The code of the button to add the event to.
     *      func =          The function to call when the button state changes.
     */
    void addButtonEvent( Buttons buttonCode, ButtonEvent func )
    {
        buttonEvents[ buttonCode ] ~= func;
    }

    /**
     * Add a button event only when the button is down.
     */
    void addButtonDownEvent( Buttons buttonCode, ButtonStateEvent func )
    {
        addButtonEvent( buttonCode, ( Buttons buttonCode, ButtonStorageType newState ) { if( newState ) func( buttonCode ); } );
    }

    /**
     * Add a button event only when the button is up.
     */
    void addButtonUpEvent( Buttons buttonCode, ButtonStateEvent func )
    {
        addButtonEvent( buttonCode, ( Buttons buttonCode, ButtonStorageType newState ) { if( !newState ) func( buttonCode ); } );
    }

    /**
     * Sets the state of the button to be assigned at the beginning of next frame.
     * Should only be called from a window controller.
     */
    void setButtonState( Buttons buttonCode, ButtonStorageType newState )
    {
        buttonStaging[ buttonCode ] = newState;
    }

private:
    /// The struct storing the state of the buttons.
    alias ButtonState       = State!( ButtonStorageType, ButtonEnum );

    /// The state of the buttons as of the beginning of the current frame.
    ButtonState buttonCurrent;
    /// The state of the buttons for the last frame.
    ButtonState buttonPrevious;
    /// The state of the buttons that has not been applied yet.
    ButtonState buttonStaging;

    /// The events tied to the buttons of this system.
    ButtonEvent[][ Buttons ] buttonEvents;
}

// If we have axes
static if( HasAxes )
{
public:
    /// The enum of axes that the input system has.
    alias Axes              = AxisState.Inputs;
    /// The type each axis is stored as.
    alias AxisStorageType   = float;
    /// A delegate that takes the changed axis and the new state.
    alias AxisEvent         = void delegate( Axes, AxisStorageType );

    /**
     * Get the state of a given axis.
     *
     * Params:
     *  axis =          The axis to get the state of.
     *
     * Returns: The state of the axis.
     */
    AxisStorageType getAxisState( Axes axis )
    {
        return axisCurrent[ axis ];
    }

    /**
     * Add an event to be fired when the given axis changes.
     *
     * Params:
     *      axis =      The name of the input to add the event to.
     *      event =     The event to trigger when the axis state changes.
     */
    void addAxisEvent( Axes axis, AxisEvent event )
    {
        axisEvents[ axis ] ~= event;
    }

    /**
     * Sets the state of the axis to be assigned at the beginning of next frame.
     * Should only be called from a window controller.
     */
    void setAxisState( Axes axisCode, AxisStorageType newState )
    {
        axisStaging[ axisCode ] = newState;
    }

private:
    /// The struct storing the state of the axes.
    alias AxisState         = State!( AxisStorageType, AxisEnum );
    /// The state of the axes as of the beginning of the current frame.
    AxisState axisCurrent;
    /// The state of the axes that has not been applied yet.
    AxisState axisStaging;

    /// The events tied to the axes of this system.
    AxisEvent[][ Axes ] axisEvents;
}
}

/**
 * Represents the state of an input method (ie. keyboard, gamepad, etc.).
 *
 * Params:
 *  T =                 The type being stored (ie. bool for keys, floats for axes, etc.).
 *  totalSize =         The number of inputs to store.
 */
struct State( T, InputEnum ) if( is( InputEnum == enum ) )
{
private:
    enum totalSize = Inputs.END;
    alias StorageType = T;
    alias Inputs = InputEnum;
public:
    T[ totalSize ] keys;

    ref typeof(this) opAssign( const ref typeof(this) other )
    {
        for( uint ii = 0; ii < other.keys.length; ++ii )
            keys[ ii ] = other.keys[ ii ];

        return this;
    }

    T opIndex( size_t keyCode ) const
    {
        return keys[ keyCode ];
    }

    T opIndexAssign( T newValue, size_t keyCode )
    {
        if( keyCode < totalSize )
            keys[ keyCode ] = newValue;

        return newValue;
    }

    Tuple!( InputEnum, T )[] opBinary( string Op : "-" )( const ref typeof(this) other )
    {
        Tuple!( InputEnum, T )[] differences;

        for( uint ii = 0; ii < keys.length; ++ii )
            if( this[ ii ] != other[ ii ] )
                differences ~= tuple( cast(InputEnum)ii, this[ ii ] );

        return differences;
    }

    void reset()
    {
        for( uint ii = 0; ii < keys.length; ++ii )
            keys[ ii ] = 0;
    }
}

// Enums of inputs
enum MouseButtons
{
    Left   = 0x01, /// Left mouse button
    Right  = 0x02, /// Right mouse button
    Middle = 0x04, /// Middle mouse button
    X1    = 0x05, /// X1 mouse button
    X2    = 0x06, /// X2 mouse button
    END,
}

/// Axes of input for the mouse.
enum MouseAxes
{
    ScrollWheel,
    XPos,
    YPos,
    END,
}

/**
 * Virtual key codes.
 *
 * From: http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
 */
enum KeyboardButtons: uint
{
    Cancel      = 0x03, /// Control-break
    //Unused    = 0x07,
    Backspace   = 0x08, /// Backspace key
    Tab         = 0x09, /// Tab key
    //Reserved  = 0x0A-0x0B,
    Clear       = 0x0C, /// Clear key
    Return      = 0x0D, /// Enter key
    //Undefined = 0x0E-0x0F
    Shift       = 0x10, /// Shift key
    Control     = 0x11, /// Control key
    Alt         = 0x12, /// Menu/alt key
    Pause       = 0x13, /// Pause key
    CapsLock    = 0x14, /// Capital/Caps Lock key
    //Who Cares = 0x15-0x1A,
    Escape      = 0x1B, /// Escape key
    //Who Cares = 0x1C-0x1F
    Space       = 0x20, /// Space bar
    PageUp      = 0x21, /// Page Up/Prior key
    PageDown    = 0x22, /// Page Down/Next key
    End         = 0x23, /// End key
    Home        = 0x24, /// Home key
    Left        = 0x25, /// Left arrow key
    Up          = 0x26, /// Up arrow key
    Right       = 0x27, /// Right arrow key
    Down        = 0x28, /// Down arrow key
    Select      = 0x29, /// Select key
    Print       = 0x2A, /// Print key
    Execute     = 0x2B, /// Execute key
    PrintScreen = 0x2C, /// Print Screen/Snapshot key
    Insert      = 0x2D, /// Insert key
    Delete      = 0x2E, /// Delete key
    Help        = 0x2F, /// Help key
    Keyboard0   = 0x30, /// 0 key
    Keyboard1   = 0x31, /// 1 key
    Keyboard2   = 0x32, /// 2 key
    Keyboard3   = 0x33, /// 3 key
    Keyboard4   = 0x34, /// 4 key
    Keyboard5   = 0x35, /// 5 key
    Keyboard6   = 0x36, /// 6 key
    Keyboard7   = 0x37, /// 7 key
    Keyboard8   = 0x38, /// 8 key
    Keyboard9   = 0x39, /// 9 key
    //Unused    = 0x3A-0x40
    A           = 0x41, /// A key
    B           = 0x42, /// B key
    C           = 0x43, /// C key
    D           = 0x44, /// D key
    E           = 0x45, /// E key
    F           = 0x46, /// F key
    G           = 0x47, /// G key
    H           = 0x48, /// H key
    I           = 0x49, /// I key
    J           = 0x4A, /// J key
    K           = 0x4B, /// K key
    L           = 0x4C, /// L key
    M           = 0x4D, /// M key
    N           = 0x4E, /// N key
    O           = 0x4F, /// O key
    P           = 0x50, /// P key
    Q           = 0x51, /// Q key
    R           = 0x52, /// R key
    S           = 0x53, /// S key
    T           = 0x54, /// T key
    U           = 0x55, /// U key
    V           = 0x56, /// V key
    W           = 0x57, /// W key
    X           = 0x58, /// X key
    Y           = 0x59, /// Y key
    Z           = 0x5A, /// Z key
    WindowsLeft = 0x5B, /// Left windows key
    WindowsRight= 0x5C, /// Right windows key
    Apps        = 0x5D, /// Applications key
    //Reserved  = 0x5E
    Sleep       = 0x5F, /// Sleep key
    Numpad0     = 0x60, /// 0 key
    Numpad1     = 0x61, /// 1 key
    Numpad2     = 0x62, /// 2 key
    Numpad3     = 0x63, /// 3 key
    Numpad4     = 0x64, /// 4 key
    Numpad5     = 0x65, /// 5 key
    Numpad6     = 0x66, /// 6 key
    Numpad7     = 0x67, /// 7 key
    Numpad8     = 0x68, /// 8 key
    Numpad9     = 0x69, /// 9 key
    Multiply    = 0x6A, /// Multiply key
    Add         = 0x6B, /// Addition key
    Separator   = 0x6C, /// Seperator key
    Subtract    = 0x6D, /// Subtraction key
    Decimal     = 0x6E, /// Decimal key
    Divide      = 0x6F, /// Division key
    F1          = 0x70, /// Function 1 key
    F2          = 0x71, /// Function 2 key
    F3          = 0x72, /// Function 3 key
    F4          = 0x73, /// Function 4 key
    F5          = 0x74, /// Function 5 key
    F6          = 0x75, /// Function 6 key
    F7          = 0x76, /// Function 7 key
    F8          = 0x77, /// Function 8 key
    F9          = 0x78, /// Function 9 key
    F10         = 0x79, /// Function 10 key
    F11         = 0x7A, /// Function 11 key
    F12         = 0x7B, /// Function 12 key
    F13         = 0x7C, /// Function 13 key
    F14         = 0x7D, /// Function 14 key
    F15         = 0x7E, /// Function 15 key
    F16         = 0x7F, /// Function 16 key
    F17         = 0x80, /// Function 17 key
    F18         = 0x81, /// Function 18 key
    F19         = 0x82, /// Function 19 key
    F20         = 0x83, /// Function 20 key
    F21         = 0x84, /// Function 21 key
    F22         = 0x85, /// Function 22 key
    F23         = 0x86, /// Function 23 key
    F24         = 0x87, /// Function 24 key
    //Unused    = 0x88-0x8F,
    NumLock     = 0x90, /// Num Lock key
    ScrollLock  = 0x91, /// Scroll Lock key
    //OEM       = 0x92-0x96,
    //Unused    = 0x97-0x9F,
    ShiftLeft   = 0xA0, /// Left shift key
    ShiftRight  = 0xA1, /// Right shift key
    ControlLeft = 0xA2, /// Left control key
    ControlRight= 0xA3, /// Right control key
    AltLeft     = 0xA4, /// Left Alt key
    AltRight    = 0xA5, /// Right Alt key
    END,
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
