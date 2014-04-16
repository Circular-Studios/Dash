/**
 * Defines the static Output class, which handles all output to the console window.
 */
module utility.output;
import utility.config;
import std.stdio, std.functional;

/**
 * The types of output.
 */
enum OutputType
{
    /// Info for developers.
    Debug,
    /// Purely informational.
    Info,
    /// Something went wrong, but it's recoverable.
    Warning,
    /// The ship is sinking.
    Error,
}

/**
 * The levels of output available.
 */
enum Verbosity
{
    /// Show me everything++.
    Debug,
    /// Show me everything.
    High,
    /// Show me things that shouldn't have happened.
    Medium,
    /// I only care about things gone horribly wrong.
    Low,
    /// I like to live on the edge.
    Off,
}

/// Alias for Output.printMessage
void log( A... )( OutputType type, A messages ) { Output.log( type, messages ); }
alias logInfo       = curry!( log, OutputType.Info );
alias logWarning    = curry!( log, OutputType.Warning );
alias logError      = curry!( log, OutputType.Error );
alias logDebug      = curry!( log, OutputType.Debug );

shared OutputManager Output;

shared static this()
{
    Output = new shared OutputManager;
}

/**
 * Static class for handling interactions with the console.
 */
shared final class OutputManager
{
public:
    /**
     * Initialize the controller.
     */
    final void initialize()
    {
        verbosity = Config.get!Verbosity( "Game.Verbosity" );
    }

    /**
     * Print a message to the console.
     */
    synchronized final void log( A... )( OutputType type, A messages ) if( A.length > 0 )
    {
        if( shouldPrint( type ) )
        {
            write( getHeader( type ) );
            
            foreach( msg; messages )
                write( msg );
            
            writeln();
        }
    }

private:
    /**
     * Caches the verbosity set in the config.
     */
    Verbosity verbosity;

    this() { }

    /**
     * Gets the header for the given output type.
     */
    final string getHeader( OutputType type )
    {
        final switch( type ) with( OutputType )
        {
            case Info:
                //SetConsoleTextAttribute( hConsole, 15 );
                return "[INFO]    ";
            case Warning:
                //SetConsoleTextAttribute( hConsole, 14 );
                return "[WARNING] ";
            case Error:
                //SetConsoleTextAttribute( hConsole, 12 );
                return "[ERROR]   ";
            case Debug:
                return "[DEBUG]   ";
        }
    }

    /**
     * TODO
     */
    final bool shouldPrint( OutputType type )
    {
        return type >= verbosity;
    }
}
