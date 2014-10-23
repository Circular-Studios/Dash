module dash.utility.data.yaml;
import dash.utility.resources, dash.utility.output;

public import yaml;
import vibe.data.serialization;
import std.traits, std.range, std.typecons, std.variant;

/// Convience alias
alias Yaml = Node;

/**
 * Serializes the given value to YAML.
 *
 * The following types of values are supported:
 *
 * All entries of an array or an associative array, as well as all R/W properties and
 * all public fields of a struct/class are recursively serialized using the same rules.
 *
 * Fields ending with an underscore will have the last underscore stripped in the
 * serialized output. This makes it possible to use fields with D keywords as their name
 * by simply appending an underscore.
 *
 * The following methods can be used to customize the serialization of structs/classes:
 *
 * ---
 * Node toYaml() const;
 * static T fromYaml( Node src );
 *
 * string toString() const;
 * static T fromString( string src );
 * ---
 *
 * The methods will have to be defined in pairs. The first pair that is implemented by
 * the type will be used for serialization (i.e. toYaml overrides toString).
*/
Node serializeToYaml( T )( T value )
{
    return serialize!( YamlSerializer )( value );
}
static assert(is(typeof( serializeToYaml( "" ) )));

/**
 * Deserializes a YAML value into the destination variable.
 *
 * The same types as for serializeToYaml() are supported and handled inversely.
 */
T deserializeYaml( T )( Node yaml )
{
    return deserialize!( YamlSerializer, T )( yaml );
}
/// ditto
T deserializeYaml( T, R )( R input ) if ( isInputRange!R && !is( R == Node ) )
{
    return deserialize!( YamlStringSerializer!R, T )( input );
}
static assert(is(typeof( deserializeYaml!string( Node( "" ) ) )));
//static assert(is(typeof( deserializeYaml!string( "" ) )));

/// Does the type support custom serialization.
enum isYamlSerializable( T ) = is( typeof( T.init.toYaml() ) == Node ) && is( typeof( T.fromYaml( Node() ) ) == T );

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

    writeln( "Dash Config find unittest" );

    auto n1 = Node( [ "test1": 10 ] );

    assert( n1.find!int( "test1" ) == 10, "Config.find error." );

    assertThrown!YAMLException(n1.find!int( "dontexist" ));

    // nested test
    auto n2 = Node( ["test2": n1] );
    auto n3 = Node( ["test3": n2] );

    assert( n3.find!int( "test3.test2.test1" ) == 10, "Config.find nested test failed");

    auto n4 = Loader.fromString( cast(char[])
                                "test3:\n" ~
                                "   test2:\n" ~
                                "       test1: 10" ).load;
    assert( n4.find!int( "test3.test2.test1" ) == 10, "Config.find nested test failed");
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
        else static if( __traits( compiles, res.getObject!T ) )
        {
            result = res.getObject!T;
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
    import std.algorithm: countUntil;

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
    bool found = node.tryFind( path, temp );

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
    assert( n1.tryFind( "test1", val ), "Config.tryFind failed." );
    assert( !n1.tryFind( "dontexist", val ), "Config.tryFind returned true." );
}

/// Serializer for vibe.d framework.
struct YamlSerializer
{
private:
    Node m_current;
    Node[] m_compositeStack;

public:
    enum isYamlBasicType( T ) = isNumeric!T || isBoolean!T || is( T == string ) || is( T == typeof(null) ) || isYamlSerializable!T;
    enum isSupportedValueType( T ) = isYamlBasicType!T || is( T == Node );

    this( Node data ) { m_current = data; }
    @disable this(this);

    //
    // serialization
    //
    Node getSerializedResult() { return m_current; }
    void beginWriteDictionary( T )() { m_compositeStack ~= Node( cast(string[])[], cast(string[])[] ); }
    void endWriteDictionary( T )() { m_current = m_compositeStack[$-1]; m_compositeStack.length--; }
    void beginWriteDictionaryEntry( T )(string name) {}
    void endWriteDictionaryEntry( T )(string name) { m_compositeStack[$-1][name] = m_current; }

    void beginWriteArray( T )( size_t ) { m_compositeStack ~= Node( cast(string[])[] ); }
    void endWriteArray( T )() { m_current = m_compositeStack[$-1]; m_compositeStack.length--; }
    void beginWriteArrayEntry( T )( size_t ) {}
    void endWriteArrayEntry( T )( size_t ) { m_compositeStack[$-1].add( m_current ); }

    void writeValue( T )( T value )
    {
        static if( is( T == Node ) )
            m_current = value;
        else static if( isYamlSerializable!T )
            m_current = value.toYaml();
        else static if( is( T == typeof(null) ) )
            m_current = Node( YAMLNull() );
        else
            m_current = Node( value );
    }

    //
    // deserialization
    //
    void readDictionary( T )( scope void delegate( string ) field_handler )
    {
        enforceYaml( m_current.isMapping, "Yaml map expected, got a " ~ ( m_current.isScalar ? "scalar" : "sequence" ) ~ " instead." );

        auto old = m_current;
        foreach( string key, Node value; m_current )
        {
            m_current = value;
            field_handler( key );
        }
        m_current = old;
    }

    void readArray( T )( scope void delegate( size_t ) size_callback, scope void delegate() entry_callback )
    {
        enforceYaml( m_current.isSequence || m_current.isScalar, "Yaml scalar or sequence expected, got a map instead." );

        if( m_current.isSequence )
        {
            auto old = m_current;
            size_callback( m_current.length );
            foreach( Node ent; old )
            {
                m_current = ent;
                entry_callback();
            }
            m_current = old;
        }
        else
        {
            entry_callback();
        }
    }

    T readValue( T )()
    {
        static if( is( T == Node ) )
            return m_current;
        else static if( isYamlSerializable!T )
            return T.fromYaml( m_current );
        else
            return m_current.get!T();
    }

    bool tryReadNull() { return m_current.isNull; }
}

unittest
{
    import std.stdio;
    writeln( "Dash Config YamlSerializer unittest" );

    Node str = serializeToYaml( "MyString" );
    assert( str.isScalar );
    assert( str.get!string == "MyString" );

    struct LetsSeeWhatHappens
    {
        string key;
        string value;
    }

    Node obj = serializeToYaml( LetsSeeWhatHappens( "Key", "Value" ) );
    assert( obj.isMapping );
    assert( obj[ "key" ] == "Key" );
    assert( obj[ "value" ] == "Value" );

    auto lswh = deserializeYaml!LetsSeeWhatHappens( obj );
    assert( lswh.key == "Key" );
    assert( lswh.value == "Value" );
}

private:
void enforceYaml( string file = __FILE__, size_t line = __LINE__ )( bool cond, lazy string message = "YAML exception" )
{
    import std.exception;
    enforceEx!Exception(cond, message, file, line);
}
