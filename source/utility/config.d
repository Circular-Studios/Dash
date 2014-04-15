/**
 * Defines the static class Config, which handles all configuration options.
 */
module utility.config;
import utility.filepath;

// Imports for conversions
import components.assets, components.lights;
import graphics.shaders;
import utility.output : Verbosity;
import utility.input : Keyboard;
import utility;

import gl3n.linalg;
import yaml;

import std.array, std.conv, std.string, std.path,
    std.typecons, std.variant, std.parallelism,
    std.traits, std.algorithm;

/**
 * Process all yaml files in a directory.
 * 
 * Params:
 *  folder =                The folder to iterate over.
 */
Node[] loadYamlDocuments( string folder )
{
    Node[] nodes;

    // Actually scan directories
    foreach( file; FilePath.scanDirectory( folder, "*.yml" ) )
    {
        auto loader = Loader( file.fullPath );
        loader.constructor = Config.constructor;

        // Iterate over all documents in a file
        foreach( doc; loader )
        {
            nodes ~= doc;
        }
    }

    return nodes;
}

/**
 * Processes all yaml files in a directory, and converts each document into an object of type T.
 * 
 * Params:
 *  folder =            The folder to look in.
 */
T[] loadYamlObjects( T )( string folder )
{
    return folder.loadYamlDocuments.map!(yml => Config.toObject!T( yml ) );
}

/**
 * Load a yaml file with the engine-specific mappings.
 * 
 * Params:
 *  filePath =              The path to file to load.
 */
Node loadYamlFile( string filePath )
{
    auto loader = Loader( filePath );
    loader.constructor = Config.constructor;
    return loader.load();
}

/**
 * Static class which handles the configuration options and YAML interactions.
 */
final abstract class Config
{
public static:
    final void initialize()
    {
        constructor = new Constructor;

        constructor.addConstructorScalar( "!Vector2", &constructVector2 );
        constructor.addConstructorMapping( "!Vector2-Map", &constructVector2 );
        constructor.addConstructorScalar( "!Vector3", &constructVector3 );
        constructor.addConstructorMapping( "!Vector3-Map", &constructVector3 );
        constructor.addConstructorScalar( "!Quaternion", &constructQuaternion );
        constructor.addConstructorMapping( "!Quaternion-Map", &constructQuaternion );
        constructor.addConstructorScalar( "!Verbosity", &constructConv!Verbosity );
        constructor.addConstructorScalar( "!Keyboard", &constructConv!Keyboard );
        constructor.addConstructorScalar( "!Shader", ( ref Node node ) => Shaders.get( node.get!string ) );
        constructor.addConstructorMapping( "!Light-Directional", &constructDirectionalLight );
        constructor.addConstructorMapping( "!Light-Ambient", &constructAmbientLight );
        constructor.addConstructorMapping( "!Light-Point", &constructPointLight );
        //constructor.addConstructorScalar( "!Texture", ( ref Node node ) => Assets.get!Texture( node.get!string ) );
        //constructor.addConstructorScalar( "!Mesh", ( ref Node node ) => Assets.get!Mesh( node.get!string ) );
        //constructor.addConstructorScalar( "!Material", ( ref Node node ) => Assets.get!Material( node.get!string ) );

        config = loadYamlFile( FilePath.Resources.ConfigFile );
    }

    /**
     * Get the element, cast to the given type, at the given path, in the given node.
     */
    final T get( T )( string path, Node node = config )
    {
        Node current = node;
        string left;
        string right = path;

        while( true )
        {
            auto split = right.countUntil( '.' );
            if( split == -1 )
            {
                return current[ right ].get!T;
            }
            else
            {
                left = right[ 0..split ];
                right = right[ split + 1..$ ];
                current = current[ left ];
            }
        }
    }
    unittest
    {
        import std.stdio;
        writeln( "Dash Config get unittest" );

        auto n1 = Node( [ "test1": 10 ] );

        assert( Config.get!int( "test1", n1 ) == 10, "Config.get error." );

        try
        {
            Config.get!int( "dontexist", n1 );
            assert( false, "Config.get didn't throw." );
        }
        catch { }
    }

    /**
    * Try to get the value at path, assign to result, and return success.
    */
    final bool tryGet( T )( string path, ref T result, Node node = config )
    {
        Node res;
        bool found = tryGet( path, res, node );

        if( found )
        {
            static if( !isSomeString!T && is( T U : U[] ) )
            {
                assert( res.isSequence, "Trying to access non-sequence node " ~ path ~ " as an array." );

                foreach( Node element; res )
                    result ~= element.get!U;
            }
            else
            {
                result = res.get!T;
            }
        }

        return found;
    }

    /// ditto
    final bool tryGet( T: Node )( string path, ref T result, Node node = config )
    {
        Node current;
        string left;
        string right = path;

        for( current = node; right.length; )
        {
            auto split = right.countUntil( '.' );

            if( split == -1 )
            {
                left = right;
                right.length = 0;
            }
            else
            {
                left = right[ 0..split ];
                right = right[ split + 1..$ ];
            }

            if( !current.isMapping || !current.containsKey( left ) )
                return false;

            current = current[ left ];
        }

        result = current;

        return true;
    }

    /// ditto
    final bool tryGet( T = Node )( string path, ref Variant result, Node node = config )
    {
        // Get the value
        T temp;
        bool found = tryGet!T( path, temp, node );

        // Assign and return results
        if( found )
            result = temp;

        return found;
    }

    @disable bool tryGet( T: Variant )( string path, ref T result, Node node = config );

    unittest
    {
        import std.stdio;
        writeln( "Dash Config tryGet unittest" );

        auto n1 = Node( [ "test1": 10 ] );

        int val;
        assert( Config.tryGet( "test1", val, n1 ), "Config.tryGet failed." );
        assert( !Config.tryGet( "dontexist", val, n1 ), "Config.tryGet returned true." );
    }

    /**
     * Get element as a file path.
     */
    final string getPath( string path )
    {
        return FilePath.ResourceHome ~ get!string( path );//buildNormalizedPath( FilePath.ResourceHome, get!string( path ) );;
    }

    final T getObject( T )( Node node )
    {
        T toReturn;

        static if( is( T == class ) )
            toReturn = new T;

        // Get each member of the type
        foreach( memberName; __traits(derivedMembers, T) )
        {
            // Make sure member is accessable
            enum protection = __traits( getProtection, __traits( getMember, toReturn, memberName ) );
            static if( protection == "public" || protection == "export" &&
                       __traits( compiles, isMutable!( __traits( getMember, toReturn, memberName ) ) ) )
            {
                // If it is a field and not a function, tryGet it's value
                static if( !__traits( compiles, ParameterTypeTuple!( __traits( getMember, toReturn, memberName ) ) ) &&
                           !__traits( compiles, isBasicType!( __traits( getMember, toReturn, memberName ) ) ) )
                {
                    // Make sure member is mutable
                    static if( isMutable!( typeof( __traits( getMember, toReturn, memberName ) ) ) )
                    {
                        tryGet( memberName, __traits( getMember, toReturn, memberName ), node );
                    }
                }
                else
                {
                    // Iterate over each overload of the function (common to have getter and setter)
                    foreach( func; __traits( getOverloads, T, memberName ) )
                    {
                        enum funcProtection = __traits( getProtection, func );
                        static if( funcProtection == "public" || funcProtection == "export" )
                        {
                            // Get the param types of the function
                            alias params = ParameterTypeTuple!func;

                            // If it can be a setter and is a property
                            static if( params.length == 1 && ( functionAttributes!func & FunctionAttribute.property ) )
                            {
                                // Else, set as temp
                                static if( is( params[ 0 ] == enum ) )
                                {
                                    string tempValue;
                                }
                                else
                                {
                                    params[ 0 ] otherTempValue;
                                    auto tempValue = cast()otherTempValue;
                                }

                                if( tryGet( memberName, tempValue, node ) )
                                    mixin( "toReturn." ~ memberName ~ " = tempValue.to!(params[0]);" );
                            }
                        }
                    }
                }
            }
        }
        
        return toReturn;
    }
    unittest
    {
        import std.stdio;
        writeln( "Dash Config getObject unittest" );

        auto t = getObject!Test( Node( ["x": 5, "y": 7, "z": 9] ) );

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

private:
    Node config;
    Constructor constructor;
}

shared(vec2) constructVector2( ref Node node )
{
    shared vec2 result;

    if( node.isMapping )
    {
        result.x = node[ "x" ].as!float;
        result.y = node[ "y" ].as!float;
    }
    else if( node.isScalar )
    {
        string[] vals = node.as!string.split();

        if( vals.length != 2 )
        {
            throw new Exception( "Invalid number of values: " ~ node.as!string );
        }

        result.x = vals[ 0 ].to!float;
        result.y = vals[ 1 ].to!float;
    }

    return result;
}

shared(vec3) constructVector3( ref Node node )
{
    shared vec3 result;

    if( node.isMapping )
    {
        result.x = node[ "x" ].as!float;
        result.y = node[ "y" ].as!float;
        result.z = node[ "z" ].as!float;
    }
    else if( node.isScalar )
    {
        string[] vals = node.as!string.split();

        if( vals.length != 3 )
        {
            throw new Exception( "Invalid number of values: " ~ node.as!string );
        }

        result.x = vals[ 0 ].to!float;
        result.y = vals[ 1 ].to!float;
        result.z = vals[ 2 ].to!float;
    }

    return result;
}

shared(quat) constructQuaternion( ref Node node )
{
    shared quat result;

    if( node.isMapping )
    {
        result.x = node[ "x" ].as!float;
        result.y = node[ "y" ].as!float;
        result.z = node[ "z" ].as!float;
        result.w = node[ "w" ].as!float;
    }
    else if( node.isScalar )
    {
        string[] vals = node.as!string.split();

        if( vals.length != 3 )
        {
            throw new Exception( "Invalid number of values: " ~ node.as!string );
        }

        result.x = vals[ 0 ].to!float;
        result.y = vals[ 1 ].to!float;
        result.z = vals[ 2 ].to!float;
        result.w = vals[ 3 ].to!float;
    }

    return result;
}

Light constructAmbientLight( ref Node node )
{
    shared vec3 color;
    Config.tryGet( "Color", color, node );
    
    return cast()new shared AmbientLight( color );
}

Light constructDirectionalLight( ref Node node )
{
    shared vec3 color;
    shared vec3 dir;

    Config.tryGet( "Color", color, node );
    Config.tryGet( "Direction", dir, node );

    return cast()new shared DirectionalLight( color, dir );
}

Light constructPointLight( ref Node node )
{
    shared vec3 color;
    float radius, falloffRate;

    Config.tryGet( "Color", color, node );
    Config.tryGet( "Radius", radius, node );
    Config.tryGet( "FalloffRate", falloffRate, node );

    return cast()new shared PointLight( color, radius, falloffRate );
}


T constructConv( T )( ref Node node ) if( is( T == enum ) )
{
    if( node.isScalar )
    {
        return node.as!string.to!T;
    }
    else
    {
        throw new Exception( "Enum must be represented as a scalar." );
    }
}
