/**
 * Defines the Dash logger, using the std.logger proposal.
 */
module dash.utility.output;
public import std.experimental.logger;

import colorize;

deprecated( "Use trace() instead" )
alias logDebug = trace;
deprecated( "Use info() instead" )
alias logInfo = info;
deprecated( "Use info() instead" )
alias logNotice = info;
deprecated( "Use warning() instead" )
alias logWarning = warning;
deprecated( "Use error() instead" )
alias logError = error;
deprecated( "Use fatal() instead" )
alias logFatal = fatal;

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
    tracef( "%s time:\t\t\t%s", name, result );
}

/**
 * Dash's custom logger.
 */
class DashLogger : FileLogger
{
    static MultiLogger multiLogger;
    static DashLogger  consoleLogger;
    static DashLogger  fileLogger;

    static this()
    {
        import dash.utility.config;

        // Create loggers
        consoleLogger   = new DashLogger( config.logging.verbosities.outputVerbosity );
        fileLogger      = new DashLogger( config.logging.verbosities.loggingVerbosity, config.logging.filePath );

        // Create multilogger
        multiLogger = new MultiLogger( LogLevel.all );
        multiLogger.insertLogger( "Dash Console Logger", consoleLogger );
        multiLogger.insertLogger( "Dash File Logger", fileLogger );
        stdlog = multiLogger;
    }

    static void initialize()
    {
        import dash.utility.config;

        consoleLogger.logLevel  = config.logging.verbosities.outputVerbosity;
        fileLogger.logLevel     = config.logging.verbosities.loggingVerbosity;
    }

    override protected void writeLogMsg( ref LogEntry payload )
    {
        import std.conv: to;
        import std.path: baseName;
        import std.array: appender;
        import std.format: formattedWrite;

        auto msg = appender!string;

        // Log file and line info in the console only
        if( !isConsole )
        {
            msg.formattedWrite(
                "[%s] {%s:%d} ",
                payload.timestamp.toSimpleString(),
                payload.file.baseName,
                payload.line,
            );
        }
        
        // Log level and message
        msg.formattedWrite(
            "%s: %s",
            payload.logLevel.to!string,
            payload.msg,
        );

        // Color and print the message
        file.cwritef( "%s\n", isConsole
                               ? msg.data.color( getColor( payload.logLevel ), bg.init, getMode( payload.logLevel ) )
                               : msg.data );
    }

private:
    bool isConsole;

    this( LogLevel level, string fileName = null )
    {
        import std.stdio: stdout;

        if( !fileName )
        {
            super( stdout, level );
            isConsole = true;
        }
        else
        {
            super( fileName, level );
            isConsole = false;
        }
    }

    fg getColor( LogLevel level )
    {
        final switch( level ) with( LogLevel ) with( fg )
        {
        case trace:
        case info:
        case off:
        case all:
            return init;
        case warning:
            return yellow;
        case error:
        case critical:
        case fatal:
            return red;
        }
    }

    mode getMode( LogLevel level )
    {
        switch( level ) with( LogLevel ) with( mode )
        {
        case critical:
            return underline;
        case fatal:
            return bold;
        default:
            return init;
        }
    }
}
