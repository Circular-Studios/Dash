module dash.utility.data.serialization;
import dash.utility.data.yaml;
import dash.utility.resources, dash.utility.math, dash.utility.output;

import vibe.data.json, vibe.data.bson, vibe.data.serialization;
import std.algorithm: map;
import std.conv: to;
import std.typecons: Tuple, tuple;
import std.math;
import std.traits: EnumMembers;
import std.meta: staticMap;
import std.variant: Algebraic;

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

/// Supported serialization formats.
enum serializationModeNames = [EnumMembers!SerializationMode[1..$]].map!(to!string);
enum serializationModeTypeids = [
    SerializationMode.Json: typeid(Json),
    SerializationMode.Bson: typeid(Bson),
    SerializationMode.Yaml: typeid(Yaml),
];

/// A tagged union of all usable Data types
alias DataContainer = Algebraic!(Json, Bson, Yaml);

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
        return deserialize!(JsonSerializer, T)( file.readText().parseJsonString() );
    }

    T handleBson()
    {
        return deserialize!(BsonSerializer, T)( Bson( Bson.Type.object, file.read().idup ) );
    }

    T handleYaml()
    {
        return deserialize!(YamlSerializer, T)( Loader( file.fullPath ).load() );
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

private template VectorPolicy(VecType) if(is_vector!VecType)
{
private:
    alias T = VecType.vt;
    enum len = VecType.dimension;

public:
    T[] toRepresentation(VecType value)
    {
        return value.vector.dup();
    }

    VecType fromRepresentation(T[] rep)
    {
        VecType value;
        value.vector = rep[0..len];
        return value;
    }
}
private template QuatPolicy(QuatType) if(is_quaternion!QuatType)
{
private:
    alias T = QuatType.qt;
    enum len = 4;

public:
    T[] toRepresentation(QuatType value)
    {
        return value.quaternion.dup();
    }

    QuatType fromRepresentation(T[] rep)
    {
        QuatType value;
        value.quaternion = rep[0..len];
        return value;
    }
}

static assert(isPolicySerializable!(VectorPolicy, vec2f));
static assert(isPolicySerializable!(VectorPolicy, vec3f));
static assert(isPolicySerializable!(VectorPolicy, vec4f));
static assert(isPolicySerializable!(QuatPolicy, quatf));

unittest
{
    void testPolicy(alias Policy, SerType)(SerType val)
    {
        assert(Policy!SerType.fromRepresentation(Policy!SerType.toRepresentation(val)),
               "Failed to translate " ~ SerType.stringof);
    }

    testPolicy!VectorPolicy(vec2f(0, 1));
    testPolicy!VectorPolicy(vec3f(0, 1, 2));
    testPolicy!VectorPolicy(vec4f(0, 1, 2, 3));
    testPolicy!QuatPolicy(  quatf(0, 1, 2, 3));
}

alias Policies = ChainedPolicy!(
        VectorPolicy,
        QuatPolicy
    );
