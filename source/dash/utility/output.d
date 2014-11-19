/**
 * Defines the Dash logger, using the std.logger proposal.
 */
module dash.utility.output;
import std.experimental.logger;
// Logging functions for the others
public import std.experimental.logger: log, logf, trace, tracef, info, infof, warning, warningf, error, errorf, critical, criticalf, fatal, fatalf;

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
abstract final class DashLogger
{
    static MultiLogger          multiLogger;
    static DashConsoleLogger    consoleLogger;
    static DashFileLogger       fileLogger;
    static DashEditorLogger     editorLogger;

    static void setDefaults()
    {
        import dash.utility.config;

        // Create loggers
        consoleLogger   = new DashConsoleLogger( config.logging.verbosities.outputVerbosity );
        fileLogger      = new DashFileLogger( config.logging.verbosities.loggingVerbosity, config.logging.filePath );
        editorLogger    = new DashEditorLogger();

        // Create multilogger
        multiLogger = new MultiLogger( LogLevel.all );
        multiLogger.insertLogger( "Dash Console Logger", consoleLogger );
        multiLogger.insertLogger( "Dash Editor Logger", editorLogger );
        stdlog = multiLogger;
    }

    static void initialize()
    {
        import dash.utility.config;

        // Reinitialize the logger with file path.
        multiLogger.removeLogger( "Dash File Logger" );
        fileLogger = new DashFileLogger( config.logging.verbosities.loggingVerbosity, config.logging.filePath );
        multiLogger.insertLogger( "Dash File Logger", fileLogger );

        // Update levels of existing loggers.
        consoleLogger.logLevel  = config.logging.verbosities.outputVerbosity;
    }
}

private:
/// Logs messages to the console
final class DashConsoleLogger : FileLogger
{
    this( LogLevel level )
    {
        import std.stdio: stdout;

        super( stdout, level );
    }

    override void writeLogMsg( ref LogEntry payload )
    {
        import std.conv: to;
        import std.path: baseName;
        import std.array: appender;
        import std.format: formattedWrite;

        auto msg = appender!string;

        // Log level and message
        msg.formattedWrite(
            "%s: %s",
            payload.logLevel.to!string,
            payload.msg,
        );

        // Color and log file
        file.cwritef( msg.data.color( payload.logLevel.getColor(), bg.init, payload.logLevel.getMode() ) );
        finishLogMsg();
    }
}

/// Logs messages to a file
final class DashFileLogger : FileLogger
{
    this( LogLevel level, string filename )
    {
        super( filename, level );
    }

    override void writeLogMsg( ref LogEntry payload )
    {
        import std.conv: to;
        import std.path: baseName;
        import std.array: appender;
        import std.format: formattedWrite;

        auto msg = appender!string;

        // Log file and line info in the console only
        msg.formattedWrite(
            "[%s] {%s:%d} %s: %s",
            payload.timestamp.toSimpleString(),
            payload.file.baseName,
            payload.line,
            payload.logLevel.to!string,
            payload.msg,
        );

        // Color and print the message
        logMsgPart( msg.data );
        finishLogMsg();
    }
}

/// Logs messages to the editor interface
final class DashEditorLogger : Logger
{
    this()
    {
        // File not actually used for anything, but required by FileLogger
        super( LogLevel.all );
    }

    override void writeLogMsg( ref LogEntry payload )
    {
        import dash.core.dgame;
        import std.conv: to;

        static struct LogMessage
        {
            string file;
            int line;
            string funcName;
            string prettyFuncName;
            string moduleName;
            LogLevel logLevel;
            string logLevelLabel;
            string timestamp;
            string msg;

            this( LogEntry entry )
            {
                file = entry.file;
                line = entry.line;
                funcName = entry.funcName;
                prettyFuncName = entry.prettyFuncName;
                moduleName = entry.moduleName;
                logLevel = entry.logLevel;
                logLevelLabel = entry.logLevel.to!string;
                timestamp = entry.timestamp.toSimpleString();
                msg = entry.msg;
            }
        }

        DGame.instance.editor.send( "dash:logger:message", LogMessage( payload ) );
    }
}

/// Helper to get the color of the log level
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

/// Helper to get the print mode of the log level
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
