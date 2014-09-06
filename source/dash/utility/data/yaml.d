module dash.utility.data.yaml;

public import yaml;
import vibe.data.serialization;
import std.traits, std.range;

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

/// Serializer for vibe.d framework.
struct YamlSerializer
{
private:
    Node m_current;
    Node[] m_compositeStack;

public:
    enum isYamlBasicType( T ) = isNumeric!T || isBoolean!T || is( T == string ) || is( T == typeof(null) );
    enum isSupportedValueType( T ) = isYamlBasicType!T || is( T == Node );
    enum isYamlSerializable( T ) = is( typeof( T.init.toYaml() ) == Node ) && is( typeof( T.fromYaml( Node() ) ) == T );

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
    void endWriteArrayEntry( T )( size_t ) { m_compositeStack[$-1] ~= m_current; }

    void writeValue( T )( T value )
    {
        static if( is( T == Node ) )
            m_current = value;
        else static if( isYamlSerializable!T )
            m_current = value.toYaml();
        else
            m_current = Node( value );
    }

    //
    // deserialization
    //
    void readDictionary( T )( scope void delegate( string ) field_handler )
    {
        enforceYaml( m_current.isMapping );

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
        enforceYaml( m_current.isSequence );

        auto old = m_current;
        size_callback( m_current.length );
        foreach( ent; old )
        {
            m_current = ent;
            entry_callback();
        }
        m_current = old;
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
    import std.json: JSONException;
    import std.exception;
    enforceEx!JSONException(cond, message, file, line);
}
