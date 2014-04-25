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
    std.traits, std.algorithm, std.file;

private Node contentNode;
private string fileToYaml( string filePath ) { return filePath.replace( "\\", "/" ).replace( "../", "" ).replace( "/", "." ); }

version( EmbedContent )
string contentYML;

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
            import utility.config;
            contentYML = import( "Content.yml" );
        }
        
    }
}

/// The node config values are stored.
Node config;

/**
 * Process all yaml files in a directory.
 * 
 * Params:
 *  folder =                The folder to iterate over.
 */
Node[] loadYamlDocuments( string folder )
{
    Node[] nodes;

    if( contentNode.isNull )
    {
        // Actually scan directories
        foreach( file; FilePath.scanDirectory( folder, "*.yml" ) )
        {
            auto loader = Loader( file.fullPath );
            loader.constructor = Config.constructor;

            try
            {
                // Iterate over all documents in a file
                foreach( doc; loader )
                {
                    nodes ~= doc;
                }
            }
            catch( YAMLException e )
            {
                logFatal( "Error parsing file ", file.baseFileName, ": ", e.msg );
            }
        }
    }
    else
    {
        auto fileNode = Config.get!Node( folder.fileToYaml, contentNode );

        foreach( string fileName, Node fileContent; fileNode )
        {
            if( fileContent.isSequence )
            {
                foreach( Node childChild; fileContent )
                    nodes ~= childChild;
            }
            else
            {
                nodes ~= fileContent;
            }
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
    if( contentNode.isNull )
    {
        auto loader = Loader( filePath ~ ".yml" );
        loader.constructor = Config.constructor;
        try
        {
            return loader.load();
        }
        catch( YAMLException e )
        {
            logFatal( "Error parsing file ", new FilePath( filePath ).baseFileName, ": ", e.msg );
            return Node();
        }  
    }
    else
    {
        return contentNode.find( filePath.fileToYaml );
    }
}

/**
 * Get the element, cast to the given type, at the given path, in the given node.
 *
 * Params:
 *  node =          The node to search.
 *  path =          The path to find the item at.
 */
final T find( T = Node )( Node node, string path )
{
    T temp;
    if( node.tryFind( path, temp ) )
        return temp;
    else
        throw new YAMLException( "Path " ~ path ~ " not found in the given node." );
}
///
unittest
{
    import std.stdio;
    import std.exception;
    
    writeln( "Dash Config get unittest" );

    auto n1 = Node( [ "test1": 10 ] );

    assert( Config.get!int( "test1", n1 ) == 10, "Config.get error." );

    assertThrown!Exception(Config.get!int( "dontexist", n1 ));
    
    // nested test
    auto n2 = Node( ["test2": n1] );
    auto n3 = Node( ["test3": n2] );
    
    assert( Config.get!int( "test3.test2.test1", n3 ) == 10, "Config.get nested test failed");
    
    auto n4 = Loader.fromString(
        "test3:\n"
        "   test2:\n"
        "       test1: 10").load;
    assert( Config.get!int( "test3.test2.test1", n4 ) == 10, "Config.get nested test failed");
}

/**
 * Try to get the value at path, assign to result, and return success.
 *
 * Params:
 *  node =          The node to search.
 *  path =          The path to look for in the node.
 *  result =        [ref] The value to assign the result to.
 *
 * Returns: Whether or not the path was found.
 */
final bool tryFind( T )( Node node, string path, ref T result ) nothrow @safe
{
    // If anything goes wrong, it means the node wasn't found.
    scope( failure ) return false;

    Node res;
    bool found = node.tryFind( path, res );

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
final bool tryFind( T: Node )( Node node, string path, ref T result ) nothrow @safe
{
    // If anything goes wrong, it means the node wasn't found.
    scope( failure ) return false;

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
final bool tryFind( T = Node )( Node node, string path, ref Variant result ) nothrow @safe
{
    // Get the value
    T temp;
    bool found = tryFind( path, temp, node );

    // Assign and return results
    if( found )
        result = temp;

    return found;
}

/**
 * You may not get a variant from a node. You may assign to one,
 * but you must specify a type to search for.
 */
@disable bool tryFind( T: Variant )( Node node, string path, ref Variant result );

unittest
{
    import std.stdio;
    writeln( "Dash Config tryFind unittest" );

    auto n1 = Node( [ "test1": 10 ] );

    int val;
    assert( Config.tryFind( "test1", val, n1 ), "Config.tryFind failed." );
    assert( !Config.tryFind( "dontexist", val, n1 ), "Config.tryFind returned true." );
}

/**
 * Get element as a file path relative to the content home.
 *
 * Params:
 *  node =          The node to search for the path in.
 *  path =          The path to search the node for.
 *
 * Returns: The value at path relative to FilePath.ResourceHome.
 */
final string findPath( Node node, string path )
{
    return FilePath.ResourceHome ~ node.find!string( path );//buildNormalizedPath( FilePath.ResourceHome, get!string( path ) );;
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

/**
 * Static class which handles the configuration options and YAML interactions.
 */
final abstract class Config
{
static:
private:
    Constructor constructor;

public:
    /**
     * TODO
     */
    final void initialize()
    {
        constructor = new Constructor;
        contentNode = Node( YAMLNull() );

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

        version( EmbedContent )
        {
            logDebug( "Using imported Content.yml file." );
            assert( contentYML, "EmbedContent version set, mixin not used." );
            import std.stream;
            auto loader = Loader.fromString( contentYML );
            loader.constructor = constructor;
            contentNode = loader.load();
        }
        else
        {
            if( exists( FilePath.Resources.CompactContentFile ~ ".yml" ) )
            {
                logDebug( "Using Content.yml file." );
                contentNode = loadYamlFile( FilePath.Resources.CompactContentFile );
            }
            else
            {
                logDebug( "Using normal content directory." );
            }
        }

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
                static if( is( T == Node ) )
                    return current[ right ];
                else
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
        import std.exception;
        
        writeln( "Dash Config get unittest" );

        auto n1 = Node( [ "test1": 10 ] );

        assert( Config.get!int( "test1", n1 ) == 10, "Config.get error." );

        assertThrown!Exception(Config.get!int( "dontexist", n1 ));
        
        // nested test
        auto n2 = Node( ["test2": n1] );
        auto n3 = Node( ["test3": n2] );
        
        assert( Config.get!int( "test3.test2.test1", n3 ) == 10, "Config.get nested test failed");
        
        auto n4 = Loader.fromString(
            "test3:\n"
            "   test2:\n"
            "       test1: 10").load;
        assert( Config.get!int( "test3.test2.test1", n4 ) == 10, "Config.get nested test failed");
    }

    deprecated( "Use global versions instead." )
    {
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
    }
}

/**
 * TODO
 */
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

/**
 * TODO
 */
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

/**
 * TODO
 */
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

/**
 * TODO
 */
Light constructAmbientLight( ref Node node )
{
    shared vec3 color;
    node.tryFind( "Color", color );
    
    return cast()new shared AmbientLight( color );
}

/**
 * TODO
 */
Light constructDirectionalLight( ref Node node )
{
    shared vec3 color;
    shared vec3 dir;

    node.tryFind( "Color", color );
    node.tryFind( "Direction", dir );

    return cast()new shared DirectionalLight( color, dir );
}

/**
 * TODO
 */
Light constructPointLight( ref Node node )
{
    shared vec3 color;
    float radius, falloffRate;

    node.tryFind( "Color", color );
    node.tryFind( "Radius", radius );
    node.tryFind( "FalloffRate", falloffRate );

    return cast()new shared PointLight( color, radius, falloffRate );
}

/**
 * TODO
 */
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
