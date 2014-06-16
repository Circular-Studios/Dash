/**
 * Defines the static Output class, which handles all output to the console window.
 */
module dash.utility.output;
import dash.utility.config;
import dlogg.strict;
import std.conv;
import std.stdio;
import std.functional;

/**
*   Custom logging level type for global logger.
*/
enum OutputType
{
    /// Debug messages, aren't compiled in release version
    Debug,
    /// Diagnostic messages about program state
    Info,
    /// Non fatal errors
    Warning,
    /// Fatal errors that usually stop application
    Error,
    /// Messages of the level don't go to output.
    /// That used with minLoggingLevel and minOutputLevel
    /// to suppress any message.
    Muted
}

/**
 * The levels of output available.
 */
enum Verbosity
{
    /// Show me everything++.
    /// Debug msgs are cut off in release
    /// version.
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

/**
 * Wrapper for logging into default logger instance
 *
 * Params:
 *   type     - level of logging
 *   messages - compile-time tuple of printable things
 *              to be written into the log.
 */
void log( A... )( OutputType type, lazy A messages )
{
    Logger.log( messages.text, type );
}
/// Wrapper for logging with Info level
alias logInfo     = curry!( log, OutputType.Info );
alias logNotice   = logInfo;
/// Wrapper for logging with Warning level
alias logWarning    = curry!( log, OutputType.Warning );
/// Wrapper for logging with Error level
alias logError      = curry!( log, OutputType.Error );
alias logFatal      = logError;

/// Special case is debug logging
/**
 *   Debug messages are removed in release build.
 */
void logDebug( A... )( A messages )
{
   debug Logger.log( messages.text, OutputType.Debug );
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

    auto result = cast(Duration)benchmark!func( 1 );
    logDebug( name, " time:\t\t\t", result );
}

/// Global instance of logger
shared GlobalLogger Logger;

shared static this()
{
    Logger = new shared GlobalLogger;
}

/**
*   Children of StyledStrictLogger with $(B initialize) method to
*   handle loading verbosity from config.
*
*   Overwrites default style to use with local OutputType.
*/
synchronized final class GlobalLogger : StyledStrictLogger!(OutputType
                , OutputType.Debug,   "Debug: %1$s",   "[%2$s] Debug: %1$s"
                , OutputType.Info,    "Info: %1$s",    "[%2$s] Info: %1$s"
                , OutputType.Warning, "Warning: %1$s", "[%2$s] Warning: %1$s"
                , OutputType.Error,   "Error: %1$s",   "[%2$s] Error: %1$s"
                , OutputType.Muted,   "",              ""
                )
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
        debug enum section = "Debug";
        else  enum section = "Release";

        enum LognameSection = "Logging.FilePath";
        enum OutputVerbositySection = "Logging."~section~".OutputVerbosity";
        enum LoggingVerbositySection = "Logging."~section~".LoggingVerbosity";

        // Try to get new path for logging
        string newFileName;
        if( config.tryFind( LognameSection, newFileName ) )
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
        if( config.tryFind( OutputVerbositySection, outputVerbosity ) )
        {
            minOutputLevel = cast(OutputType)( outputVerbosity );
        }
        else
        {
            debug minOutputLevel = OutputType.Info;
            else minOutputLevel = OutputType.Warning;
        }

        // Try to get logging verbosity from config
        Verbosity loggingVerbosity;
        if( config.tryFind( LoggingVerbositySection, loggingVerbosity ) )
        {
            minLoggingLevel = cast(OutputType)( loggingVerbosity );
        }
        else
        {
            debug minLoggingLevel = OutputType.Info;
            else minLoggingLevel = OutputType.Warning;
        }
    }
}
