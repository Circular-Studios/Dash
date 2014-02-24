/**
 * Defines the static Input class, which is responsible for handling all keyboard/mouse/controller interactions.
 */
module utility.input;
import utility.config, utility.filepath, utility.output;

import yaml;
import std.typecons, std.conv;

final abstract class Input
{
public static:
	/**
	 * Function called when key event triggers.
	 */
	alias void delegate( uint, bool ) KeyEvent;
	alias void delegate( uint ) KeyStateEvent;

	/**
	 * Processes Config/Input.yml and pulls input string bindings.
	 */
	final void initialize()
	{
		auto bindings = Config.loadYaml( FilePath.Resources.InputBindings );

		foreach( key; keyBindings.keys )
			keyBindings.remove( key );

		foreach( string name, Node bind; bindings )
		{
			log( OutputType.Info, "Binding ", name );

			if( bind.isScalar )
			{
				keyBindings[ name ] = bind.get!Keyboard;
			}
			else if( bind.isSequence )
			{
				foreach( Node child; bind )
				{
					try
					{
						keyBindings[ name ] = child.get!Keyboard;
					}
					catch
					{
						log( OutputType.Error, "Failed to parse keybinding for input ", name );
					}
				}
			}
			else if( bind.isMapping )
			{
				foreach( string type, Node value; bind )
				{
					final switch( type )
					{
						case "Keyboard":
							try
							{
								keyBindings[ name ] = value.get!Keyboard;
							}
							catch
							{
								try
								{
									keyBindings[ name ] = value.get!string.to!Keyboard;
								}
								catch
								{
									log( OutputType.Error, "Failed to parse keybinding for input ", name );
								}
							}

							break;
					}
				}
			}
		}
	}

	/**
	 * Updates the key states, and calls all key events.
	 */
	final void update()
	{
		auto diff = staging - current;

		previous = current;
		current = staging;
		staging.reset();

		foreach( state; diff )
			if( auto keyEvent = state[ 0 ] in keyEvents )
				foreach( event; *keyEvent )
					event( state[ 0 ], state[ 1 ] );
	}

	/**
	 * Add an event to be fired when the given key changes.
	 * 
	 * Params:
	 * 		keyCode =	The code of the key to add the event to.
	 * 		func =		The function to call when the key state changes.
	 */
	final void addKeyEvent( uint keyCode, KeyEvent func )
	{
		keyEvents[ keyCode ] ~= func;
	}

	/**
	 * Add a key event only when the key is down.
	 */
	final void addKeyDownEvent( uint keyCode, KeyStateEvent func )
	{
		keyEvents[ keyCode ] ~= ( uint keyCode, bool newState ) { if( newState ) func( newState ); };
	}

	/**
	 * Add a key event only when the key is up.
	 */
	final void addKeyUpEvent( uint keyCode, KeyStateEvent func )
	{
		keyEvents[ keyCode ] ~= ( uint keyCode, bool newState ) { if( !newState ) func( keyCode ); };
	}

	/**
	 * Check if a given key is down.
	 * 
	 * Params:
	 * 		keyCode =		The code of the key to check.
	 * 		checkPrevious =	Whether or not to make sure the key was down last frame.
	 */
	final bool isKeyDown( uint keyCode, bool checkPrevious = false )
	{
		return current[ keyCode ] && ( !checkPrevious || !previous[ keyCode ] );
	}

	/**
	 * Check if a given key is up.
	 * 
	 * Params:
	 * 		keyCode =		The code of the key to check.
	 * 		checkPrevious =	Whether or not to make sure the key was up last frame.
	 */
	final bool isKeyUp( uint keyCode, bool checkPrevious = false )
	{
		return !current[ keyCode ] && ( !checkPrevious || previous[ keyCode ] );
	}

	/**
	 * Sets the state of the key to be assigned at the beginning of next frame.
	 * Should only be called from a window controller.
	 */
	final void setKeyState( uint keyCode, bool newState )
	{
		staging[ keyCode ] = newState;
	}

	/**
	 * Gets the state of a string-bound input.
	 *
	 * Params:
	 *		input =			The input to check for.
	 * 		checkPrevious =	Whether or not to make sure the key was up last frame.
	 */
	final T getState( T = bool )( string input, bool checkPrevious = false ) if( is( T == bool ) /*|| is( T == float )*/ )
	{
		static if( is( T == bool ) )
		{
			if( input in keyBindings )
			{
				return isKeyDown( keyBindings[ input ], checkPrevious );
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

private:
	Keyboard[ string ] keyBindings;

	KeyEvent[][ uint ] keyEvents;

	KeyState current;
	KeyState previous;
	KeyState staging;

	struct KeyState
	{
	public:
		enum TotalSize = 256u;
		enum ElementSize = uint.sizeof;
		enum Split = TotalSize / ElementSize;

		uint[ Split ] keys;

		ref KeyState opAssign( const ref KeyState other )
		{
			for( uint ii = 0; ii < Split; ++ii )
				keys[ ii ] = other.keys[ ii ];

			return this;
		}

		bool opIndex( size_t keyCode ) const
		{
			return ( keys[ keyCode / ElementSize ] & getBitAtIndex( keyCode ) ) != 0;
		}

		bool opIndexAssign( bool newValue, size_t keyCode )
		{
			keys[ keyCode / ElementSize ] = getBitAtIndex( keyCode ) & uint.max;
			return newValue;
		}

		Tuple!( uint, bool )[] opBinary( string Op : "-" )( const ref KeyState other )
		{
			Tuple!( uint, bool )[] differences;

			for( uint ii = 0; ii < TotalSize; ++ii )
				if( this[ ii ] != other[ ii ] )
					differences ~= Tuple!( uint, bool )( ii, this[ ii ] );

			return differences;
		}

		void reset()
		{
			for( uint ii = 0; ii < Split; ++ii )
				keys[ ii ] = 0;
		}

	private:
		static uint getBitAtIndex( size_t keyCode )
		{
			return 1 << ( keyCode % Split );
		}
	}
}

/**
 * Virtual key codes.
 *
 * From: http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
 */
enum Keyboard: uint
{
	MouseLeft	= 0x01, /// Left mouse button
	MouseRight	= 0x02, /// Right mouse button
	Cancel		= 0x03, /// Control-break
	MouseMiddle	= 0x04, /// Middle mouse button
	XButton1	= 0x05, /// X1 mouse button
	XButton2	= 0x06, /// X2 mouse button
	//Unused	= 0x07,
	Backspace	= 0x08, /// Backspace key
	Tab			= 0x09, /// Tab key
	//Reserved	= 0x0A-0x0B,
	Clear		= 0x0C, /// Clear key
	Return		= 0x0D, /// Enter key
	//Undefined	= 0x0E-0x0F
	Shift		= 0x10, /// Shift key
	Control		= 0x11, /// Control key
	Alt			= 0x12, /// Menu/alt key
	Pause		= 0x13, /// Pause key
	CapsLock	= 0x14, /// Capital/Caps Lock key
	//Who Cares	= 0x15-0x1A,
	Escape		= 0x1B, /// Escape key
	//Who Cares	= 0x1C-0x1F
	Space		= 0x20, /// Space bar
	PageUp		= 0x21, /// Page Up/Prior key
	PageDown	= 0x22, /// Page Down/Next key
	End			= 0x23, /// End key
	Home		= 0x24, /// Home key
	Left		= 0x25, /// Left arrow key
	Up			= 0x26, /// Up arrow key
	Right		= 0x27, /// Right arrow key
	Down		= 0x28, /// Down arrow key
	Select		= 0x29, /// Select key
	Print		= 0x2A, /// Print key
	Execute		= 0x2B, /// Execute key
	PrintScreen	= 0x2C, /// Print Screen/Snapshot key
	Insert		= 0x2D, /// Insert key
	Delete		= 0x2E, /// Delete key
	Help		= 0x2F, /// Help key
	Keyboard0	= 0x30, /// 0 key
	Keyboard1	= 0x31, /// 1 key
	Keyboard2	= 0x32, /// 2 key
	Keyboard3	= 0x33, /// 3 key
	Keyboard4	= 0x34, /// 4 key
	Keyboard5	= 0x35, /// 5 key
	Keyboard6	= 0x36, /// 6 key
	Keyboard7	= 0x37, /// 7 key
	Keyboard8	= 0x38, /// 8 key
	Keyboard9	= 0x39, /// 9 key
	//Unused	= 0x3A-0x40
	A			= 0x41, /// A key
	B			= 0x42, /// B key
	C			= 0x43, /// C key
	D			= 0x44, /// D key
	E			= 0x45, /// E key
	F			= 0x46, /// F key
	G			= 0x47, /// G key
	H			= 0x48, /// H key
	I			= 0x49, /// I key
	J			= 0x4A, /// J key
	K			= 0x4B, /// K key
	L			= 0x4C, /// L key
	M			= 0x4D, /// M key
	N			= 0x4E, /// N key
	O			= 0x4F, /// O key
	P			= 0x50, /// P key
	Q			= 0x51, /// Q key
	R			= 0x52, /// R key
	S			= 0x53, /// S key
	T			= 0x54, /// T key
	U			= 0x55, /// U key
	V			= 0x56, /// V key
	W			= 0x57, /// W key
	X			= 0x58, /// X key
	Y			= 0x59, /// Y key
	Z			= 0x5A, /// Z key
	WindowsLeft	= 0x5B, /// Left windows key
	WindowsRight= 0x5C, /// Right windows key
	Apps		= 0x5D, /// Applications key
	//Reserved	= 0x5E
	Sleep		= 0x5F, /// Sleep key
	Numpad0		= 0x60, /// 0 key
	Numpad1		= 0x61, /// 1 key
	Numpad2		= 0x62, /// 2 key
	Numpad3		= 0x63, /// 3 key
	Numpad4		= 0x64, /// 4 key
	Numpad5		= 0x65, /// 5 key
	Numpad6		= 0x66, /// 6 key
	Numpad7		= 0x67, /// 7 key
	Numpad8		= 0x68, /// 8 key
	Numpad9		= 0x69, /// 9 key
	Multiply	= 0x6A, /// Multiply key
	Add			= 0x6B, /// Addition key
	Separator	= 0x6C, /// Seperator key
	Subtract	= 0x6D, /// Subtraction key
	Decimal		= 0x6E, /// Decimal key
	Divide		= 0x6F, /// Division key
	F1			= 0x70, /// Function 1 key
	F2			= 0x71, /// Function 2 key
	F3			= 0x72, /// Function 3 key
	F4			= 0x73, /// Function 4 key
	F5			= 0x74, /// Function 5 key
	F6			= 0x75, /// Function 6 key
	F7			= 0x76, /// Function 7 key
	F8			= 0x77, /// Function 8 key
	F9			= 0x78, /// Function 9 key
	F10			= 0x79, /// Function 10 key
	F11			= 0x7A, /// Function 11 key
	F12			= 0x7B, /// Function 12 key
	F13			= 0x7C, /// Function 13 key
	F14			= 0x7D, /// Function 14 key
	F15			= 0x7E, /// Function 15 key
	F16			= 0x7F, /// Function 16 key
	F17			= 0x80, /// Function 17 key
	F18			= 0x81, /// Function 18 key
	F19			= 0x82, /// Function 19 key
	F20			= 0x83, /// Function 20 key
	F21			= 0x84, /// Function 21 key
	F22			= 0x85, /// Function 22 key
	F23			= 0x86, /// Function 23 key
	F24			= 0x87, /// Function 24 key
	//Unused	= 0x88-0x8F,
	NumLock		= 0x90, /// Num Lock key
	ScrollLock	= 0x91, /// Scroll Lock key
	//OEM		= 0x92-0x96,
	//Unused	= 0x97-0x9F,
	ShiftLeft	= 0xA0, /// Left shift key
	ShiftRight	= 0xA1, /// Right shift key
	ControlLeft	= 0xA2, /// Left control key
	ControlRight= 0xA3, /// Right control key
	AltLeft		= 0xA4, /// Left Alt key
	AltRight	= 0xA5, /// Right Alt key
}
