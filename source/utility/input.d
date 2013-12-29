/**
 * Defines the static Input class, which is responsible for handling all keyboard/mouse/controller interactions.
 */
module utility.input;

import std.typecons;

static class Input
{
static:
public:
	/**
	 * Function called when key event triggers.
	 */
	alias void delegate( uint, bool ) KeyEvent;
	alias void delegate( uint ) KeyStateEvent;

	/**
	 * Updates the key states.
	 */
	void update()
	{
		auto diff = staging - current;

		previous = current;
		current = staging;
		staging.reset();

		foreach( state; diff )
			foreach( event; keyEvents[ state[ 0 ] ] )
				event( state[ 0 ], state[ 1 ] );
	}

	/**
	 * Add an event to be fired when the given key changes.
	 * 
	 * Params:
	 * 		keyCode =	The code of the key to add the event to.
	 * 		func =		The function to call when the key state changes.
	 */
	void addKeyEvent( uint keyCode, KeyEvent func )
	{
		keyEvents[ keyCode ] ~= func;
	}

	/**
	 * Add a key event only when the key is down.
	 */
	void addKeyDownEvent( uint keyCode, KeyStateEvent func )
	{
		keyEvents[ keyCode ] ~= ( uint keyCode, bool newState ) { if( newState ) func( newState ); };
	}

	/**
	 * Add a key event only when the key is up.
	 */
	void addKeyUpEvent( uint keyCode, KeyStateEvent func )
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
	bool isKeyDown( uint keyCode, bool checkPrevious = false )
	{
		return current[ keyCode ] && ( !checkPrevious || previous[ keyCode ] );
	}

	/**
	 * Check if a given key is up.
	 * 
	 * Params:
	 * 		keyCode =		The code of the key to check.
	 * 		checkPrevious =	Whether or not to make sure the key was up last frame.
	 */
	bool isKeyUp( uint keyCode, bool checkPrevious = false )
	{
		return !current[ keyCode ] && ( !checkPrevious || !previous[ keyCode ] );
	}

	/**
	 * Sets the state of the key to be assigned at the beginning of next frame.
	 * Should only be called from a window controller.
	 */
	void setKeyState( uint keyCode, bool newState )
	{
		staging[ keyCode ] = newState;
	}

private:
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
