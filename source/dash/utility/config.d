/**
 * Defines the static class Config, which handles all configuration options.
 */
module dash.utility.config;
import dash.components.component;
import dash.utility.resources, dash.utility.output, dash.utility.data;

public import yaml;

import std.variant, std.algorithm, std.traits, std.range,
       std.array, std.conv, std.file, std.typecons, std.path;

/**
 * Place this mixin anywhere in your game code to allow the Content.yml file
 * to be imported at compile time. Note that this will only actually import
 * the file when EmbedContent is listed as a defined version.
 */
mixin template ContentImport()
{
    version( EmbedContent )
    {
        static this()
        {
            import dash.utility.config;
            contentYML = import( "Content.yml" );
        }
    }
}

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

unittest
{
    import std.stdio;
    writeln( "Dash Config getObject unittest" );

    auto t = Node( ["x": 5, "y": 7, "z": 9] ).getObject!Test();

    assert( t.x == 5 );
    assert( t.y == 7 );
    assert( t.z == 9 );
}
version(unittest) class Test
{
    int x;
    int y;
    private int _z;

    @property int z() { return _z; }
    @property void z( int newZ ) { _z = newZ; }
}

/**
 * Static class which handles the configuration options and YAML interactions.
 */
final abstract class Config
{
public static:
    /**
     * TODO
     */
    void initialize()
    {
        version( EmbedContent )
        {
            logDebug( "Using imported Content.yml file." );
            assert( contentYML, "EmbedContent version set, mixin not used." );
            auto loader = Loader.fromString( contentYML );
            loader.constructor = constructor;
            contentNode = loader.load();
            // Null content yml so it can be collected.
            contentYML = null;
        }
        else version( unittest )
        {
            auto loader = Loader.fromString( testYML );
            loader.constructor = constructor;
            contentNode = loader.load();
        }
        else
        {
            if( exists( Resources.CompactContentFile ) )
            {
                logDebug( "Using Content.yml file." );
                configFile = Resource( Resources.CompactContentFile );
                contentNode = Resources.CompactContentFile.loadYamlFile();
            }
            else
            {
                logDebug( "Using normal content directory." );
                configFile = Resource( Resources.ConfigFile );
            }
        }

        config = Resources.ConfigFile.loadYamlFile();
    }

    void refresh()
    {
        // No need to refresh, there can be no changes.
        version( EmbedContent ) { }
        else
        {
            if( exists( Resources.CompactContentFile ) )
            {
                logDebug( "Using Content.yml file." );
                if( configFile.needsRefresh )
                {
                    contentNode = Node( YAMLNull() );
                    contentNode = Resources.CompactContentFile.loadYamlFile();
                    config = Resources.ConfigFile.loadYamlFile();
                }
            }
            else
            {
                logDebug( "Using normal content directory." );
                if( configFile.needsRefresh )
                    config = Resources.ConfigFile.loadYamlFile();
            }
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
