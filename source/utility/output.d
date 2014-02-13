/**
 * Defines the static Output class, which handles all output to the console window.
 */
module utility.output;
import utility.config;
import std.stdio;

/**
 * The types of output.
 */
enum OutputType
{
	/// Purely informational.
	Info,
	/// Something went wrong, but it's recoverable.
	Warning,
	/// The ship is sinking.
	Error
}

/**
 * The levels of output available.
 */
enum Verbosity
{
	/// Show me everything.
	High,
	/// Show me just warnings and errors.
	Medium,
	/// I only care about things gone horribly wrong.
	Low,
	/// I like to live on the edge.
	Off
}

/// Alias for Output.printMessage
alias Output.printMessage log;
/// Alias for Output.printValue
alias Output.printValue logValue;

/**
 * Static class for handling interactions with the console.
 */
final abstract class Output
{
public static:
	/**
	 * Initialize the controller.
	 */
	final void initialize()
	{
		verbosity = Config.get!Verbosity( "Game.Verbosity" );
	}

	/**
	 * Print a generic message to the console.
	 */
	final void printMessage( A... )( OutputType type, A messages )
	{
		if( shouldPrint( type ) )
		{
			write( getHeader( type ) );

			foreach( msg; messages )
				write( msg );

			writeln();
		}
	}

	/**
	 * Print the value of a variable.
	 */
	final void printValue( T )( OutputType type, string varName, T value )
	{
		if( shouldPrint( type ) )
			writefln( "%s %s: %s", getHeader( type ), varName, value );
	}

private:
	/**
	 * Caches the verbosity set in the config.
	 */
	Verbosity verbosity;

	/**
	 * Gets the header for the given output type.
	 */
	final string getHeader( OutputType type )
	{
		switch( type )
		{
			case OutputType.Info:
				//SetConsoleTextAttribute( hConsole, 15 );
				return "[INFO]   ";
			case OutputType.Warning:
				//SetConsoleTextAttribute( hConsole, 14 );
				return "[WARNING]";
			case OutputType.Error:
				//SetConsoleTextAttribute( hConsole, 12 );
				return "[ERROR]  ";
			default:
				return "         ";
		}
	}

	final bool shouldPrint( OutputType type )
	{
		return type >= verbosity;
	}
}
