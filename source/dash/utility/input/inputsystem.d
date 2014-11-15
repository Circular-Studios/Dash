/**
 * Defines InputSystem and State, which are used for defining an input device (keyboard, mouse, gamepad, etc.)
 */
module dash.utility.input.inputsystem;
import dash.utility.input.input;

import std.typecons, std.traits;

package:
/// The type each button is stored as.
alias ButtonStorageType = bool;
/// The type each axis is stored as.
alias AxisStorageType   = float;

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

package:
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

            Input.processDiffs!(typeof(this))( diffButtons );
        }
        static if( HasAxes )
        {
            auto diffAxis = axisStaging - axisCurrent;
            axisCurrent = axisStaging;

            foreach( state; diffAxis )
                if( auto axisEvent = state[ 0 ] in axisEvents )
                    foreach( event; *axisEvent )
                        event( state[ 0 ], state[ 1 ] );

            Input.processDiffs!(typeof(this))( diffAxis );
        }
    }

// If we have buttons
static if( HasButtons )
{
public:
    /// The enum of buttons that the input system has.
    alias Buttons           = ButtonState.Inputs;
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
    deprecated( "Use Input.addButtonEvent with a binding instead." )
    void addButtonEvent( Buttons buttonCode, ButtonEvent func )
    {
        buttonEvents[ buttonCode ] ~= func;
    }

    /**
     * Add a button event only when the button is down.
     */
    deprecated( "Use Input.addButtonDownEvent with a binding instead." )
    void addButtonDownEvent( Buttons buttonCode, ButtonStateEvent func )
    {
        addButtonEvent( buttonCode, ( Buttons buttonCode, ButtonStorageType newState ) { if( newState ) func( buttonCode ); } );
    }

    /**
     * Add a button event only when the button is up.
     */
    deprecated( "Use Input.addButtonUpEvent with a binding instead." )
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
        // HACK: Don't mind me.
        import dash.utility.input.mouse, dash.core.dgame, dash.graphics.graphics;
        import dash.utility.bindings.awesomium;
        version( Windows ) {
        static if( is( Buttons == MouseButtons ) )
        {
            if( buttonCode == MouseButtons.Left )
            {
                auto ui = DGame.instance.activeScene.ui;
                auto mousePos = Input.mousePos;
                auto offset = ( Graphics.width * (mousePos.y - 1) + mousePos.x ) * 4;
                auto transparency = ui.view.glBuffer[ offset + 3 ];

                import dash.utility.output;
                tracef( "Transparency at point %d, %d: %d", cast(int)mousePos.x, cast(int)( Graphics.height - mousePos.y ), transparency );

                if( ui && newState && transparency > 0 )
                {
                    awe_webview_inject_mouse_down( ui.view.webView, awe_mousebutton.AWE_MB_LEFT );
                }
                else
                {
                    buttonStaging[ buttonCode ] = newState;

                    if( !newState )
                    {
                        awe_webview_inject_mouse_up( ui.view.webView, awe_mousebutton.AWE_MB_LEFT );
                    }
                }
            }
            else
            {
                buttonStaging[ buttonCode ] = newState;
            }
        }
        else
        {
            buttonStaging[ buttonCode ] = newState;
        }
        }
        else
        {
            buttonStaging[ buttonCode ] = newState;
        }
    }

private:
    /// The struct storing the state of the buttons.
    alias ButtonState = State!( ButtonStorageType, ButtonEnum );

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
    deprecated( "Use Input.addAxisEvent with a binding instead." )
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
    alias AxisState = State!( AxisStorageType, AxisEnum );
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
    // enum totalSize = Inputs.END;
    enum totalSize = EnumMembers!Inputs.length;
    alias StorageType = T;
    alias Inputs = InputEnum;
public:
    T[ size_t ] keys;

    ref typeof(this) opAssign( const ref typeof(this) other )
    {
        foreach(size_t index, T value; other.keys)
        {
            keys[index] = value;
        }

        return this;
    }

    T opIndex( size_t keyCode ) 
    {
        // If the key being pressed doesn't have 
        // an entry in keys, add it, and set it
        // to the default value
        if( !( keyCode in keys ) )
            keys[ keyCode ] = cast(T)0;

        return keys[ keyCode ];
    }

    T opIndexAssign( T newValue, size_t keyCode )
    {
        keys[ keyCode ] = newValue;

        return newValue;
    }

    Tuple!( InputEnum, T )[] opBinary( string Op : "-" )( ref typeof(this) other )
    {
        Tuple!( InputEnum, T )[] differences;

        foreach( size_t index, T value; keys)
            if( value != other[ index ] )
                differences ~= tuple( cast(InputEnum)index, value );

        return differences;
    }

    void reset()
    {
        foreach( ii; keys.keys )
            keys[ ii ] = cast(T)0;
    }
}