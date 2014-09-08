module dash.utility.data.serialization;
import dash.utility.resources;
import dash.utility.data.yaml;
import vibe.data.json, vibe.data.bson;

// Serialization attributes
public import vibe.data.serialization: asArray, byName, ignore, name, optional;
/// Rename a field in the ddl.
alias rename = name;

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
        throw new Exception( "Not implemented." );
    }

    T handleYaml()
    {
        Yaml content = Loader.fromString( file.readText() ).load();
        return deserializeYaml!T( content );
    }

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

/**
 * Serializes an object to a file.
 */
template serializeToFile( bool prettyPrint = true )
{
    void serializeToFile( T )( T t, string outPath, SerializationMode mode = SerializationMode.Default )
    {
        import std.path: extension;
        import std.string: toLower;
        import std.file: File;

        void handleJson()
        {
            writeJsonString!( File, prettyPrint )( new File( outPath ), serializeToJson( t ) );
        }

        void handleBson()
        {
            throw new Exception( "Not implemented." );
        }

        void handleYaml()
        {
            throw new Exception( "Not implemented." );
        }

        final switch( mode ) with( SerializationMode )
        {
            case Json: handleJson(); break;
            case Bson: handleBson(); break;
            case Yaml: handleYaml(); break;
            case Default:
                switch( file.extension.toLower )
                {
                    case ".json": handleJson(); break;
                    case ".bson": handleBson(); break;
                    case ".yaml":
                    case ".yml":  handleYaml(); break;
                    default: throw new Exception( "File extension " ~ file.extension.toLower ~ " not supported." );
                }
                break;
        }
    }
}
