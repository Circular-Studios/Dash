module dash.utility.data.serialization;
import dash.utility.data.yaml;
import dash.utility.resources, dash.utility.math, dash.utility.output;

import vibe.data.json, vibe.data.bson;
import std.typecons: Tuple, tuple;
import std.typetuple;
import std.math;

// Serialization attributes
public import vibe.data.serialization: rename = name, asArray, byName, ignore, optional, isCustomSerializable;

/**
 * Modes of serialization.
 */
enum SerializationMode
{
    Default,
    Json,
    Bson,
    Yaml,
}

/**
 * Deserializes a file.
 *
 * Params:
 *  fileName =          The name of the file to deserialize.
 *
 * Returns: The deserialized object.
 */
Tuple!( T, Resource ) deserializeFileByName( T )( string fileName, SerializationMode mode = SerializationMode.Default )
{
    import std.path: dirName, baseName;
    import std.array: empty, front;

    auto files = fileName.dirName.scanDirectory( fileName.baseName ~ ".*" );
    return files.empty
        ? tuple( T.init, internalResource )
        : tuple( deserializeFile!T( files.front ), files.front );
}

/**
 * Deserializes a file.
 *
 * Params:
 *  file =              The name of the file to deserialize.
 *
 * Returns: The deserialized object.
 */
T deserializeFile( T )( Resource file, SerializationMode mode = SerializationMode.Default )
{
    import std.path: extension;
    import std.string: toLower;

    T handleJson()
    {
        return deserializeJson!T( file.readText().parseJsonString() );
    }

    T handleBson()
    {
        return deserializeBson!T( Bson( Bson.Type.object, file.read().idup ) );
    }

    T handleYaml()
    {
        return deserializeYaml!T( Loader( file.fullPath ).load() );
    }

    try
    {
        final switch( mode ) with( SerializationMode )
        {
            case Json: return handleJson();
            case Bson: return handleBson();
            case Yaml: return handleYaml();
            case Default:
                switch( file.extension.toLower )
                {
                    case ".json": return handleJson();
                    case ".bson": return handleBson();
                    case ".yaml":
                    case ".yml":  return handleYaml();
                    default: throw new Exception( "File extension " ~ file.extension.toLower ~ " not supported." );
                }
        }
    }
    catch( Exception e )
    {
        errorf( "Error deserializing file %s to type %s: %s", file.fileName, T.stringof, e.msg );
        return T.init;
    }
}

/**
 * Deserializes a file with multiple documents.
 *
 * Params:
 *  file =              The name of the file to deserialize.
 *
 * Returns: The deserialized object.
 */
T[] deserializeMultiFile( T )( Resource file, SerializationMode mode = SerializationMode.Default )
{
    import std.path: extension;
    import std.string: toLower;

    T[] handleJson()
    {
        return [deserializeFile!T( file, SerializationMode.Json )];
    }

    T[] handleBson()
    {
        return [deserializeFile!T( file, SerializationMode.Bson )];
    }

    T[] handleYaml()
    {
        import std.algorithm: map;
        import std.array: array;
        return Loader( file.fullPath )
            .loadAll()
            .map!( node => node.deserializeYaml!T() )
            .array();
    }

    try
    {
        final switch( mode ) with( SerializationMode )
        {
            case Json: return handleJson();
            case Bson: return handleBson();
            case Yaml: return handleYaml();
            case Default:
                switch( file.extension.toLower )
                {
                    case ".json": return handleJson();
                    case ".bson": return handleBson();
                    case ".yaml":
                    case ".yml":  return handleYaml();
                    default: throw new Exception( "File extension " ~ file.extension.toLower ~ " not supported." );
                }
        }
    }
    catch( Exception e )
    {
        errorf( "Error deserializing file %s to type %s: %s", file.fileName, T.stringof, e.msg );
        return [];
    }
}

/**
 * Serializes an object to a file.
 */
template serializeToFile( bool prettyPrint = true )
{
    void serializeToFile( T )( T t, string outPath, SerializationMode mode = SerializationMode.Default )
    {
        import std.path: extension;
        import std.string: toLower;
        import std.file: write;
        import std.array: appender;

        void handleJson()
        {
            auto json = appender!string;
            writeJsonString!( typeof(json), prettyPrint )( json, serializeToJson( t ) );
            write( outPath, json.data );
        }

        void handleBson()
        {
            write( outPath, serializeToBson( t ).data );
        }

        void handleYaml()
        {
            Dumper( outPath ).dump( serializeToYaml( t ) );
        }

        try
        {
            final switch( mode ) with( SerializationMode )
            {
                case Json: handleJson(); break;
                case Bson: handleBson(); break;
                case Yaml: handleYaml(); break;
                case Default:
                    switch( outPath.extension.toLower )
                    {
                        case ".json": handleJson(); break;
                        case ".bson": handleBson(); break;
                        case ".yaml":
                        case ".yml":  handleYaml(); break;
                        default: throw new Exception( "File extension " ~ outPath.extension.toLower ~ " not supported." );
                    }
                    break;
            }
        }
        catch( Exception e )
        {
            errorf( "Error serializing %s to file %s: %s", T.stringof, file.fileName, e.msg );
        }
    }
}

/// Supported serialization formats.
enum serializationFormats = tuple( "Json", "Bson", "Yaml" );

/// Type to use when defining custom
struct CustomSerializer( _T, _Rep, alias _ser, alias _deser, alias _check )
    if( is( typeof( _ser( _T.init ) ) == _Rep ) &&
        is( typeof( _deser( _Rep.init ) ) == _T ) &&
        is( typeof( _check( _Rep.init ) ) == bool ) )
{
    /// The type being serialized
    alias T = _T;
    /// The serialized representation
    alias Rep = _Rep;
    /// Function to convert the type to its rep
    alias serialize = _ser;
    /// Function to convert the rep to the type
    alias deserialize = _deser;
    /// Function called to ensure the representation is valid
    alias check = _check;
}

/// For calling templated templates.
template PApply( alias Target, T... )
{
    alias PApply( U... ) = Target!( T, U );
}

/// Checks if a serializer is for a type.
enum serializerTypesMatch( Type, alias CS ) = is( CS.T == Type );

/// Predicate for std.typetupple
alias isSerializerFor( T ) = PApply!( serializerTypesMatch, T );

/// Does a given type have a serializer
enum hasSerializer( T ) = anySatisfy!( isSerializerFor!T, customSerializers );

/// Get the serializer for a type
template serializerFor( T )
{
    static if( hasSerializer!T )
        alias serializerFor = Filter!( isSerializerFor!T, customSerializers )[ 0 ];
    else
        alias serializerFor = defaultSerializer!T;
}

/// A tuple of all supported serializers
alias customSerializers = TypeTuple!(
    CustomSerializer!( vec2f, float[], vec => [ vec.x, vec.y ], arr => vec2f( arr ), arr => arr.length == 2 ),
    CustomSerializer!( vec3f, float[], vec => [ vec.x, vec.y, vec.z ], arr => vec3f( arr ), arr => arr.length == 3 ),
    CustomSerializer!( quatf, float[], vec => vec.toEulerAngles.vector[], arr => fromEulerAngles( arr ), arr => arr.length == 3 ),
);
static assert( hasSerializer!vec2f );
static assert( hasSerializer!vec3f );
static assert( hasSerializer!quatf );

/// Serializer for all other types
alias defaultSerializer( T ) = CustomSerializer!( T, T, t => t, t => t, t => true );
