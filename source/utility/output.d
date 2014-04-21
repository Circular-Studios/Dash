/**
 * Defines the static Output class, which handles all output to the console window.
 */
module utility.output;
import utility.config;
import dlogg.strict;
import std.conv;
import std.stdio;
import std.functional;

// to not import dlogg every time you call log function
public import dlogg.log : LoggingLevel; 

/**
 * The types of output.
 * Deprecated: use $(B LoggingLevel).
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
    /// Deprecated, debug msgs are cut off in release
    /// version anyway. So equal High.
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

/// Wrapper for logging into default logger instance
/**
*   Params:
*   type     - level of logging
*   messages - compile-time tuple of printable things
*              to be written into the log.
*/
void log( A... )( LoggingLevel type, lazy A messages )
{
    Logger.log( messages.text, type );
}
/// Wrapper for logging with Notice level
alias logNotice     = curry!( log, LoggingLevel.Notice );
/// Alias for backward compatibility
alias logInfo       = logNotice;
/// Wrapper for logging with Warning level
alias logWarning    = curry!( log, LoggingLevel.Warning );
/// Wrapper for logging with Fatal level
alias logFatal      = curry!( log, LoggingLevel.Fatal );
/// Alias for backward compatibility
alias logError      = logFatal;

/// Special case is debug logging
/**
*   Debug messages are removed in release build.
*/
void logDebug( A... )( A messages )
{
    Logger.logDebug( messages );
}

/// Alias for Output.printMessage
deprecated("Use dlogg.log.LoggingLevel instead") 
void log( A... )( OutputType type, A messages ) 
{ 
    Output.log( type, messages ); 
}

/**
 * Benchmark the running of a function, and log the result to the debug buffer.
 *
 * Params:
 *  func =              The function to benchmark
 *  name =              The name to print in the log
 */
void bench( alias func )( lazy string name )
{
    import std.datetime, core.time;
    logDebug( name, " time:\t\t\t", cast(Duration)benchmark!func( 1 ) );
}

/// Global instance of logger
shared GlobalLogger Logger;

// Deprecated manager for console output
shared OutputManager Output;

shared static this()
{
    Logger = new shared GlobalLogger;
    Output = new shared OutputManager;
}

/**
*   Children of StrictLogger with $(B initialize) method to
*   handle loading verbosity from config.
*/
shared final class GlobalLogger : StrictLogger
{
    enum DEFAULT_LOG_NAME = "dash-preinit.log";
    
    this()
    {
        super(DEFAULT_LOG_NAME);
    }
    
    /**
    *   Loads verbosity from config.
    */
    final void initialize()
    {
        // Verbosity is more clearer for users than logging level
        LoggingLevel mapVerbosity(Verbosity verbosity)
        {
            final switch(verbosity)
            {
                // Debug messages are cut off in release version any way
                case(Verbosity.Debug):  return LoggingLevel.Notice;
                case(Verbosity.High):   return LoggingLevel.Notice;
                case(Verbosity.Medium): return LoggingLevel.Warning;
                case(Verbosity.Low):    return LoggingLevel.Fatal;
                case(Verbosity.Off):    return LoggingLevel.Muted;
            }
        }
        
        debug enum section = "Debug";
        else  enum section = "Release";
        
        enum LognameSection = "Logging.FilePath";
        enum OutputVerbositySection = "Logging."~section~".OutputVerbosity";
        enum LoggingVerbositySection = "Logging."~section~".LoggingVerbosity";
        
        // Try to get new path for logging
        string newFileName;
        if( Config.tryGet!string( LognameSection, newFileName ) )
        {
            string oldFileName = this.name; 
            try
            {
                this.name = newFileName;
            } 
            catch( Exception e )
            {
                std.stdio.writeln( "Error: Failed to reload new log location from '",oldFileName,"' to '",newFileName,"'" );
                std.stdio.writeln( "Reason: ", e.msg );
                debug std.stdio.writeln( e.toString );
                
                // Try to rollback
                scope(failure) {} 
                this.name = oldFileName;
            }
        }
        
        // Try to get output verbosity from config
        Verbosity outputVerbosity;
        if( Config.tryGet!Verbosity( OutputVerbositySection, outputVerbosity ) )
        {
            minOutputLevel = mapVerbosity( outputVerbosity ); 
        } 
        else
        {
            debug minOutputLevel = LoggingLevel.Notice;
            else minOutputLevel = LoggingLevel.Warning; 
        }
        
        // Try to get logging verbosity from config
        Verbosity loggingVerbosity;
        if( Config.tryGet!Verbosity( LoggingVerbositySection, loggingVerbosity ) )
        {
            minLoggingLevel = mapVerbosity( loggingVerbosity );
        } 
        else
        {
            debug minLoggingLevel = LoggingLevel.Notice;
            else minLoggingLevel = LoggingLevel.Warning; 
        }
    }
}

/**
 *  Static class for handling interactions with the console.
 *  Deprecated: use GlobalLogger instead
 */
shared final class OutputManager
{
public:
    /**
     * Initialize the controller.
     */
    final void initialize()
    {
        verbosity = Verbosity.High;
        Config.tryGet!Verbosity( "Game.Verbosity", verbosity );
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

    this()
    {
        verbosity = Verbosity.High;
    }

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
