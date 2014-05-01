/**
 * Defines the static Input class, which is responsible for handling all keyboard/mouse/controller interactions.
 */
module utility.input;
import utility, core, graphics;

import yaml, gl3n.linalg;
import derelict.opengl3.gl3;
import core.sync.mutex;
import std.typecons, std.conv;

/**
 * Manages all input events.
 */
final abstract class Input
{
public static:
    /**
     * Processes Config/Input.yml and pulls input string bindings.
     */
    final void initialize()
    {
        auto bindings = FilePath.Resources.InputBindings.loadYamlFile();

        // Init states
        currentKeys.reset();
        previousKeys.reset();
        stagingKeys.reset();
        currentAxis.reset();
        stagingAxis.reset();

        foreach( key; keyBindings.keys )
            keyBindings.remove( key );

        foreach( key; keyEvents.keys )
            keyEvents.remove( key );

        foreach( key; axisEvents.keys )
            axisEvents.remove( key );

        foreach( string name, Node bind; bindings )
        {
            if( bind.isMapping )
            {
                foreach( string type, Node value; bind )
                {
                    enum parseType( string type, string enumName = type ) = q{
                        case "$type":
                            try
                            {
                                keyBindings[ name ] ~= value.get!string.to!$enumName;
                            }
                            catch( Exception e )
                            {
                                logFatal( "Failed to parse keybinding for input ", name, ": ", e.msg );
                            }
                            break;
                    }.replaceMap( [ "$type": type, "$enumName": enumName ] );

                    final switch( type )
                    {
                        mixin( parseType!"Keyboard" );
                        mixin( parseType!( "Axis", q{Axes} ) );
                    }
                }
            }
            else
            {
                logWarning( "Unsupported input format for ", name, "." );
            }
        }
    }

    /**
     * Updates the key states, and calls all key events.
     */
    final void update()
    {
        auto diffKeys = stagingKeys - currentKeys;
        previousKeys = currentKeys;
        currentKeys = stagingKeys;

        auto diffAxis = stagingAxis - currentAxis;
        currentAxis = stagingAxis;

        foreach( state; diffKeys )
            if( auto keyEvent = state[ 0 ] in keyEvents )
                foreach( event; *keyEvent )
                    event( state[ 0 ], state[ 1 ] );

        foreach( state; diffAxis )
            if( auto axisEvent = state[ 0 ] in axisEvents )
                foreach( event; *axisEvent )
                    event( state[ 0 ], state[ 1 ] );
    }

    /**
     * Add an event to be fired when the given key changes.
     *
     * Params:
     *      keyCode =   The code of the key to add the event to.
     *      func =      The function to call when the key state changes.
     */
    final void addKeyEvent( uint keyCode, KeyEvent func )
    {
        keyEvents[ keyCode ] ~= func;
    }
    unittest
    {
        import std.stdio;
        writeln( "Dash Input addKeyEvent unittest" );

        Config.initialize();
        Input.initialize();

        bool keyDown;
        Input.addKeyEvent( Keyboard.Space, ( uint keyCode, bool newState )
        {
            keyDown = newState;
        } );

        Input.setKeyState( Keyboard.Space, true );
        Input.update();
        assert( keyDown );

        Input.setKeyState( Keyboard.Space, false );
        Input.update();
        assert( !keyDown );
    }

    /**
     * Add an event to be fired when the given key changes.
     *
     * Params:
     *      inputName = The name of the input to add the event to.
     *      func =      The function to call when the key state changes.
     */
    final void addKeyEvent( string inputName, KeyEvent func )
    {
        if( auto keys = inputName in keyBindings )
            foreach( key; *keys )
                addKeyEvent( key, func );
    }

    /**
     * Add a key event only when the key is down.
     */
    final void addKeyDownEvent( uint keyCode, KeyStateEvent func )
    {
        addKeyEvent( keyCode, ( uint keyCode, bool newState ) { if( newState ) func( newState ); } );
    }

    /**
     * Add a key event only when the key is down.
     */
    final void addKeyDownEvent( string inputName, KeyStateEvent func )
    {
        if( auto keys = inputName in keyBindings )
            foreach( key; *keys )
                addKeyEvent( key, ( uint keyCode, bool newState ) { if( newState ) func( keyCode ); } );
    }

    /**
     * Add a key event only when the key is up.
     */
    final void addKeyUpEvent( uint keyCode, KeyStateEvent func )
    {
        addKeyEvent( keyCode, ( uint keyCode, bool newState ) { if( !newState ) func( keyCode ); } );
    }

    /**
     * Add a key event only when the key is up.
     */
    final void addKeyUpEvent( string inputName, KeyStateEvent func )
    {
        if( auto keys = inputName in keyBindings )
            foreach( key; *keys )
                addKeyEvent( key, ( uint keyCode, bool newState ) { if( !newState ) func( keyCode ); } );
    }

    /**
     * Add an event to be fired when the given axis changes.
     *
     * Params:
     *      inputName = The name of the input to add the event to.
     *      func =      The function to call when the key state changes.
     */
    final void addAxisEvent( uint keyCode, AxisEvent func )
    {
        axisEvents[ keyCode ] ~= func;
    }

    /**
     * Check if a given key is down.
     *
     * Params:
     *      keyCode =       The code of the key to check.
     *      checkPrevious = Whether or not to make sure the key was down last frame.
     */
    final bool isKeyDown( uint keyCode, bool checkPrevious = false )
    {
        return currentKeys[ keyCode ] && ( !checkPrevious || !previousKeys[ keyCode ] );
    }
    unittest
    {
        import std.stdio;
        writeln( "Dash Input isKeyDown unittest" );

        Config.initialize();
        Input.initialize();
        Input.setKeyState( Keyboard.Space, true );

        Input.update();
        assert( Input.isKeyDown( Keyboard.Space, true ) );
        assert( Input.isKeyDown( Keyboard.Space, false ) );

        Input.update();
        assert( !Input.isKeyDown( Keyboard.Space, true ) );
        assert( Input.isKeyDown( Keyboard.Space, false ) );
    }

    /**
     * Check if a given key is up.
     *
     * Params:
     *      keyCode =       The code of the key to check.
     *      checkPrevious = Whether or not to make sure the key was up last frame.
     */
    final bool isKeyUp( uint keyCode, bool checkPrevious = false )
    {
        return !currentKeys[ keyCode ] && ( !checkPrevious || previousKeys[ keyCode ] );
    }
    unittest
    {
        import std.stdio;
        writeln( "Dash Input isKeyUp unittest" );

        Config.initialize();
        Input.initialize();
        Input.setKeyState( Keyboard.Space, true );

        Input.update();
        Input.setKeyState( Keyboard.Space, false );

        Input.update();
        assert( Input.isKeyUp( Keyboard.Space, true ) );
        assert( Input.isKeyUp( Keyboard.Space, false ) );

        Input.update();
        assert( !Input.isKeyUp( Keyboard.Space, true ) );
        assert( Input.isKeyUp( Keyboard.Space, false ) );
    }

    /**
     * Get the state of a given access
     *
     * Params:
     *  axisCod =       The axis to get the state of.
     *
     * Returns: The value of axis.
     */
    final float getAxisState( uint axisCode )
    {
        return currentAxis[ axisCode ];
    }

    /**
     * Sets the state of the key to be assigned at the beginning of next frame.
     * Should only be called from a window controller.
     */
    final void setKeyState( uint keyCode, bool newState )
    {
        stagingKeys[ keyCode ] = newState;
    }

    /**
     * Sets the state of the axis to be assigned at the beginning of next frame.
     * Should only be called from a window controller.
     */
    final void setAxisState( uint axisCode, float newState )
    {
        stagingAxis[ axisCode ] = newState;
    }

    /**
     * Gets the state of a string-bound input.
     *
     * Params:
     *      input =         The input to check for.
     *      checkPrevious = Whether or not to make sure the key was up last frame.
     */
    final T getState( T = bool )( string input, bool checkPrevious = false ) if( is( T == bool ) /*|| is( T == float )*/ )
    {
        static if( is( T == bool ) )
        {
            bool result = false;

            if( auto keys = input in keyBindings )
            {
                foreach( key; *keys )
                    result = result || isKeyDown( key, checkPrevious );

                return result;
            }
            else
            {
                throw new Exception( "Input " ~ input ~ " not bound." );
            }
        }
        /*else static if( is( T == float ) )
        {

        }*/
    }

    /**
     * Gets the position of the cursor.
     *
     * Returns:     The position of the mouse cursor.
     */
    final @property vec2 mousePos()
    {
        version( Windows )
        {
            import graphics;
            import win32.windows;
            POINT i;
            GetCursorPos( &i );
            ScreenToClient( Win32.get().hWnd, &i );

            // Adjust for border
            if( !Graphics.adapter.fullscreen )
            {
                i.x -= GetSystemMetrics( SM_CXBORDER );
                i.y -= GetSystemMetrics( SM_CYBORDER );
            }

            return vec2( cast(float)i.x, Graphics.height - cast(float)i.y );
        }
        else version( linux )
        {
            return vec2();
        }
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The position of the mouse cursor in world space.
     */
    final @property vec3 mousePosView()
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
        vec2 mouse = mousePos;
        float depth;
        int x = cast(int)mouse.x;
        int y = cast(int)mouse.y;
        auto view = vec3( 0, 0, 0 );

        if( x >= 0 && x <= Graphics.width && y >= 0 && y <= Graphics.height )
        {
            glBindFramebuffer( GL_FRAMEBUFFER, Graphics.deferredFrameBuffer );
            glReadBuffer( GL_DEPTH_ATTACHMENT );
            glReadPixels( x, y, 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &depth);

            auto linearDepth = scene.camera.projectionConstants.x / ( scene.camera.projectionConstants.y - depth );
            //Convert x and y to normalized device coords
            float screenX = ( mouse.x / cast(float)Graphics.width ) * 2 - 1;
            float screenY = -( ( mouse.y / cast(float)Graphics.height ) * 2 - 1 );

            auto viewSpace = scene.camera.inversePerspectiveMatrix * vec4( screenX, screenY, 1.0f, 1.0f);
            auto viewRay = vec3( viewSpace.xy * (1.0f / viewSpace.z), 1.0f);
            view = viewRay * linearDepth;

            glBindFramebuffer( GL_FRAMEBUFFER, 0 );
        }

        return view;
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The position of the mouse cursor in world space.
     */
    final @property vec3 mousePosWorld()
    {
        return (DGame.instance.activeScene.camera.inverseViewMatrix * vec4( mousePosView(), 1.0f )).xyz;
    }

    /**
     * Gets the world position of the cursor in the active scene.
     *
     * Returns:     The GameObject located at the current mouse Position
     */
    final @property GameObject mouseObject()
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

        vec2 mouse = mousePos();
        float fId;
        int x = cast(int)mouse.x;
        int y = cast(int)mouse.y;

        if( x >= 0 && x <= Graphics.width && y >= 0 && y <= Graphics.height )
        {
            glBindFramebuffer( GL_FRAMEBUFFER, Graphics.deferredFrameBuffer );
            glReadBuffer( GL_COLOR_ATTACHMENT1 );
            glReadPixels( x, y, 1, 1, GL_BLUE, GL_FLOAT, &fId);

            uint id = cast(int)(fId);
            glBindFramebuffer( GL_FRAMEBUFFER, 0 );

            if(id > 0)
                return scene[id];
        }

        return null;
    }

private:
    uint[][ string ] keyBindings;

    KeyEvent[][ uint ] keyEvents;
    AxisEvent[][ uint ] axisEvents;

    KeyboardKeyState currentKeys;
    KeyboardKeyState previousKeys;
    KeyboardKeyState stagingKeys;

    KeyboardAxisState currentAxis;
    KeyboardAxisState stagingAxis;
}

private:
/* EVENT TYPES */
/// Function called when key event triggers.
alias KeyEvent          = void delegate( uint, bool );
/// ditto
alias KeyStateEvent     = void delegate( uint );
/// Function called when key event triggers.
alias AxisEvent         = void delegate( uint, float );

/* STATES */
/// The state of the keyboard keys.
alias KeyboardKeyState  = State!( bool, 256 );
/// The state of the keyboard axes (mouse pos, mouse wheel, etc.).
alias KeyboardAxisState = State!( float, 2 );

/**
 * Represents the state of an input method (ie. keyboard, gamepad, etc.).
 *
 * Params:
 *  T =                 The type being stored (ie. bool for keys, floats for axes, etc.).
 *  totalSize =         The number of inputs to store.
 */
struct State( T, uint totalSize )
{
public:
    T[ totalSize ] keys;

    ref State!( T, totalSize ) opAssign( const ref State!( T, totalSize ) other )
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
        keys[ keyCode ] = newValue;
        return newValue;
    }

    Tuple!( uint, T )[] opBinary( string Op : "-" )( const ref State!( T, totalSize ) other )
    {
        Tuple!( uint, T )[] differences;

        for( uint ii = 0; ii < keys.length; ++ii )
            if( this[ ii ] != other[ ii ] )
                differences ~= tuple( ii, this[ ii ] );

        return differences;
    }

    void reset()
    {
        for( uint ii = 0; ii < keys.length; ++ii )
            keys[ ii ] = 0;
    }
}

// Enums of inputs
public:
/// Axes of input
enum Axes: uint
{
    MouseScroll,
}

/**
 * Virtual key codes.
 *
 * From: http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
 */
enum Keyboard: uint
{
    MouseLeft   = 0x01, /// Left mouse button
    MouseRight  = 0x02, /// Right mouse button
    Cancel      = 0x03, /// Control-break
    MouseMiddle = 0x04, /// Middle mouse button
    XButton1    = 0x05, /// X1 mouse button
    XButton2    = 0x06, /// X2 mouse button
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
}
