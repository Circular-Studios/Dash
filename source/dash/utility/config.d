/**
 * Defines the static class Config, which handles all configuration options.
 */
module dash.utility.config;
import dash.utility.resources, dash.utility.data;

import std.experimental.logger;
import std.datetime;

/**
 * The global instance of config.
 */
private Config configInst;
/// ditto
const(Config) config() @property
{
    return configInst;
}

enum WindowType
{
    Fullscreen,
    FullscreenWindowed,
    Windowed,
    BorderlessWindow
}

/**
 * Static class which handles the configuration options and YAML interactions.
 */
struct Config
{
public:
    @rename( "Logging" ) @optional
    LoggerSettings logging;
    @rename( "Display" ) @optional
    DisplaySettings display;
    @rename( "Graphics" ) @optional
    GraphicsSettings graphics;
    @rename( "UserInterface" ) @optional
    UserInterfaceSettings userInterface;
    @rename( "Editor" ) @optional
    EditorSettings editor;

    static struct LoggerSettings
    {
        @rename( "FilePath" ) @optional
        string filePath = "dash.log";
        @rename( "Debug" ) @optional
        Verbosities debug_ = Verbosities( LogLevel.all, LogLevel.all );
        @rename( "Release" ) @optional
        Verbosities release = Verbosities( LogLevel.off, LogLevel.error );

        @ignore
        Verbosities verbosities() const @property pure @safe nothrow @nogc
        {
            debug return debug_;
            else  return release;
        }

        static struct Verbosities
        {
            @rename( "OutputVerbosity" ) @optional @byName
            LogLevel outputVerbosity = LogLevel.info;
            @rename( "LoggingVerbosity" ) @optional @byName
            LogLevel loggingVerbosity = LogLevel.all;
        }
    }

    static struct DisplaySettings
    {
        @rename( "WindowType" ) @optional @byName
        WindowType windowMode = WindowType.Windowed;
        @rename( "Height" ) @optional
        uint height = 1920;
        @rename( "Width" ) @optional
        uint width = 720;
    }

    static struct GraphicsSettings
    {
        @rename( "BackfaceCulling" ) @optional
        bool backfaceCulling = true;
        @rename( "VSync" ) @optional
        bool vsync = false;
        @rename( "OpenGL33" ) @optional
        bool usingGl33 = false;
    }

    static struct UserInterfaceSettings
    {
        @rename( "FilePath" ) @optional
        string filePath = null;
    }

    static struct EditorSettings
    {
        @rename( "Port" ) @optional
        ushort port = 8080;
        @rename( "Route" ) @optional
        string route = "ws";
    }

static:
    @ignore
    private Resource resource = internalResource;

    void initialize()
    {
        auto res = deserializeFileByName!Config( Resources.ConfigFile );
        configInst = res[ 0 ];
        resource = res[ 1 ];
    }

    void refresh()
    {
        if( resource.needsRefresh )
        {
            configInst = deserializeFile!Config( resource );
        }
    }
}
