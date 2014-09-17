/**
 * Defines the static class Config, which handles all configuration options.
 */
module dash.utility.config;
import dash.components.component;
import dash.utility.resources, dash.utility.output, dash.utility.data;

public import yaml;

import std.datetime;

/**
 * Get a YAML map as a D object of type T.
 *
 * Params:
 *  T =             The type to get from the node.
 *  node =          The node to turn into the object.
 *
 * Returns: An object of type T that has all fields from the YAML node assigned to it.
 */
deprecated( "Use deserializeYaml" )
alias getObject = deserializeYaml;

/**
 * The global instance of config.
 */
private Config configInst;
/// ditto
const(Config) config() @property
{
    return configInst;
}

/**
 * Static class which handles the configuration options and YAML interactions.
 */
struct Config
{
public:
    LoggerSettings Logging;
    DisplaySettings Display;
    GraphicsSettings Graphics;
    UserInterfaceSettings UserInterface;
    EditorSettings Editor;

    static struct LoggerSettings
    {
        string FilePath;
        Verbosities Debug;
        Verbosities Release;

        static struct Verbosities
        {
            Verbosity OutputVerbosity;
            Verbosity LoggingVerbosity;
        }
    }

    static struct DisplaySettings
    {
        bool Fullscreen;
        uint Height;
        uint Width;
    }

    static struct GraphicsSettings
    {
        bool BackfaceCulling;
        bool VSync;
    }

    static struct UserInterfaceSettings
    {
        string FilePath;
    }

    static struct EditorSettings
    {
        ushort Port;
    }

static:
    private Resource resource = Resource( "" );
    private SysTime lastModified;

    void initialize()
    {
        import std.file: timeLastModified;

        auto res = deserializeFileByName!Config( Resources.ConfigFile );
        config = res[ 0 ];
        resource = res[ 1 ];
        lastModified = resource.fullPath.timeLastModified;
    }

    void update()
    {
        import std.file: timeLastModified;

        if( lastModified < resource.fullPath.timeLastModified )
        {
            config = deserializeFile( resource );
            lastModified = resource.fullPath.timeLastModified;
        }
    }
}

/**
 * TODO
 */
T constructConv( T )( ref Node node ) if( is( T == enum ) )
{
    if( node.isScalar )
    {
        return node.get!string.to!T;
    }
    else
    {
        throw new Exception( "Enum must be represented as a scalar." );
    }
}

version( unittest )
{
    import std.string;
    /// The string to store test yaml content in.
    string testYML = q{---
Config:
    Input:
        Forward:
            Keyboard: W
        Backward:
            Keyboard: S
        Jump:
            Keyboard: Space
    Config:
        Logging:
            FilePath: "dash.log"
            Debug:
                OutputVerbosity: !Verbosity Debug
                LoggingVerbosity: !Verbosity Debug
            Release:
                OutputVerbosity: !Verbosity Medium
                LoggingVerbosity: !Verbosity Medium
        Display:
            Fullscreen: false
            Height: 720
            Width: 1280
        Graphics:
            BackfaceCulling: true
            VSync: false
        Physics:
            Gravity: !Vector3 0.0 -10.0 0.0
        UserInterface:
            FilePath: "uitest.html"
            Scale: !Vector2 1.0 1.0
    };
}
