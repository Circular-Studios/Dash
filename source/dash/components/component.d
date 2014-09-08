/**
 * Defines the IComponent interface, which is the base for all components.
 */
module dash.components.component;
import dash.core, dash.components, dash.graphics, dash.utility;

import vibe.data.bson, vibe.data.json, dash.utility.data.yaml;
import std.algorithm, std.array, std.string, std.traits, std.conv, std.typecons;

/// Tests if a type can be created from yaml.
enum isYamlObject(T) = __traits( compiles, { T obj; obj.yaml = Node( YAMLNull() ); } );
enum isComponent(alias T) = is( T == class ) && is( T : Component ) && !__traits( isAbstractClass, T );
enum serializationFormats = tuple( "Json"/*, "Bson"/*, "Yaml"*/ );
private enum perSerializationFormat( string code ) = "".reduce!( ( working, type ) => working ~ code.replace( "$type", type ) )( serializationFormats );
alias helper( alias T ) = T;
alias helper() = TypeTuple!();

auto append( Begin, End )( Begin begin, End end )
{
    return tuple( begin.expand, end );
}

abstract class YamlObject
{
public:
    @ignore
    Node yaml;

    /// Called when refreshing an object.
    void refresh() { }

    this()
    {
        yaml = Node( YAMLNull() );
    }
}

/**
 * Interface for components to implement.
 */
abstract class Component : YamlObject
{
public:
    /// The node that defined the component.
    Node yaml;
    /// The GameObject that owns this component.
    GameObject owner;

    /// The function called on initialization of the object.
    void initialize() { }
    /// Called on the update cycle.
    void update() { }
    /// Called on the draw cycle.
    void draw() { }
    /// Called on shutdown.
    void shutdown() { }

    // For serialization.
    mixin( perSerializationFormat!q{
        static $type delegate( Component )[ ClassInfo ] $typeSerializers;
        static Component delegate( $type )[ string ] $typeDeserializers;
        $type to$type() const
        {
            return $typeSerializers[ typeid(this) ]( cast()this );
        }
        static Component from$type( $type d )
        {
            if( auto type = "Type" in d )
            {
                return $typeDeserializers[ type.get!string ]( d );
            }
            else
            {
                logWarning( "Component doesn't have \"Type\" field." );
                return null;
            }
        }
    } );

    const(Description)* description() @property
    {
        if( auto desc =  typeid(this) in descriptions )
            return desc;
        else
            assert( false, "ComponentDescription not found for type " ~ typeid(this).name );
    }

    /// The description for the component
    struct Description
    {
    public:
        static struct Field
        {
        public:
            string name;
            string typeName;
            string attributes;
            string mod;
        }

        Field[] fields;
    }

private:
    static const(Description)[ ClassInfo ] descriptions;
}

/**
 * To be placed at the top of any module defining YamlComponents.
 *
 * Params:
 *  modName =           The name of the module to register.
 */
enum registerComponents( string modName = __MODULE__ ) = q{
    static this()
    {
        // Declarations
        import mod = $modName;

        // Foreach definition in the module (classes, structs, functions, etc.)
        foreach( memberName; __traits( allMembers, mod ) )
        {
            // Alais to the member
            alias member = helper!( __traits( getMember, mod, memberName ) );

            // If member is a class that extends Componen
            static if( isComponent!member )
            {
                componentMetadata!( member ).register();
            }
        }
    }
}.replace( "$modName", modName );

/// Registers a type as a component
template componentMetadata( T ) if( isComponent!T )
{
public:
    // Runtime function, registers serializers
    void register()
    {
        // Generate serializers for the type
        mixin( perSerializationFormat!q{
            Component.$typeSerializers[ typeid(T) ] = ( Component c )
            {
                return $type();
                //return serializeTo$type( SerializationDescription( cast(T)c ) );
            };

            Component.$typeDeserializers[ typeid(T).name ] = ( $type node )
            {
                return null;
                //return deserialize$type!( SerializationDescription )( node ).createInstance();
            };
        } );

        Component.descriptions[ typeid(T) ] = description;
    }

    // Generate actual struct
    struct SerializationDescription
    {
        mixin( descContents );

        enum fields = getFields();

        // Create a description from a component.
        this( T theThing )
        {
            foreach( field; __traits( allMembers, T ) )
            {
                static if( fields.map!(f => f.name).canFind( field ) )
                {
                    mixin( field ~ " = theThing." ~ field ~ ";\n" );
                }
            }
        }

        // Create a component from a description.
        T createInstance()
        {
            T comp = new T;
            foreach( field; __traits( allMembers, T ) )
            {
                static if( fields.map!(f => f.name).canFind( field ) )
                {
                    mixin( "comp." ~ field ~ " = this." ~ field ~ ";\n" );
                }
            }
            return comp;
        }
    }

    // Generate description
    enum description = Component.Description( getFields() );

private:
    // Get a list of fields on the type
    Component.Description.Field[] getFields( size_t idx = 0 )( Component.Description.Field[] fields = [] )
    {
        static if( idx == __traits( allMembers, T ).length )
        {
            return fields;
        }
        else
        {
            enum memberName = helper!( __traits( allMembers, T )[ idx ] );

            // Make sure member is accessable and that we care about it
            static if( !memberName.among( "this", "~this", __traits( allMembers, Component ) ) &&
                        is( typeof( helper!( __traits( getMember, T, memberName ) ) ) ) )
            {
                alias member = helper!( __traits( getMember, T, memberName ) );

                // Process variables
                static if( !isSomeFunction!member )
                {
                    import std.conv;
                    alias attributes = helper!( __traits( getAttributes, member ) );

                    // Get string form of attributes
                    string attributesStr()
                    {
                        static if( is( attributes.length ) )
                            return attributes.array.map!( attr => attr.to!string ).join( ", " ).to!string;
                        else static if( is( attributes.to!string ) )
                            return attributes.to!string;
                        else
                        {
                            __ctfeWriteln( "No attributes on member " ~ memberName );
                            return null;
                        }
                    }

                    // Get required module import name
                    static if( __traits( compiles, moduleName!( typeof( member ) ) ) )
                        enum modName = moduleName!(typeof(member));
                    else
                        enum modName = null;

                    // Generate field
                    enum newField = Component.Description.Field( memberName, fullyQualifiedName!(Unqual!(typeof(member))), attributesStr, modName );
                    return getFields!( idx + 1 )( fields ~ newField );
                }
                else
                {
                    return getFields!( idx + 1 )( fields );
                }
            }
            else
            {
                return getFields!( idx + 1 )( fields );
            }
        }
    }

    // Generate static description struct for deserializing
    enum descContents = {
        return reduce!( ( working, field )
            {
                string result = working;

                // Append required import for variable type
                if( field.mod )
                    result ~= "import " ~ field.mod ~ ";\n";

                // Append variable attributes
                if( field.attributes )
                    result ~= "@(" ~ field.attributes ~ ") ";

                // Append variable declaration
                result ~= field.typeName ~ " " ~ field.name ~ ";\n";

                return result;
            }
        )( "", description.fields );
    } ();
}

/**
 * Meant to be added to components that can be set from YAML.
 * Example:
 * ---
 * @yamlObject("Test")
 * class Test : YamlObject
 * {
 *     @field("X")
 *     int x;
 * }
 * ---
 */
auto yamlObject( string name = "" )
{
    return YamlUDA( YamlType.Object, name, null );
}

/**
 * Meant to be added to components that can be set from YAML.
 * Example:
 * ---
 * @yamlComponent("Test")
 * class Test : Component
 * {
 *     @field("X")
 *     int x;
 * }
 * ---
 */
auto yamlComponent( string loader = "null" )( string name = "" )
{
    return YamlUDA( YamlType.Component, name, mixin( loader ) );
}

/**
 * Meant to be added to members for making them YAML accessible.
 *
 * Params:
 *  name =              The name of the tag in YAML.
 *  loader =            If cannot be loaded directly, specify function used to load it.
 *
 * Example:
 * ---
 * @yamlComponent("Test")
 * class Test : Component
 * {
 *     @field("X")
 *     int x;
 * }
 * ---
 */
/*
auto field( string name = "" )
{
    return YamlUDA( YamlType.Field, name, null );
}
*/
deprecated( "Use rename instead." )
alias field = rename;

/// Used to create objects from yaml. The key is the YAML name of the type.
Object delegate( Node )[string] createYamlObject;
/// Used to create components from yaml. The key is the YAML name of the type.
Component delegate( Node )[string] createYamlComponent;
/// Refresh any object defined from yaml. The key is the typeid of the type.
void delegate( Object, Node )[TypeInfo] refreshYamlObject;

enum YamlType { Object, Component, Field }
private alias LoaderFunction = YamlObject delegate( string );

struct YamlUDA
{
    YamlType type;
    string name;
    LoaderFunction loader;
}
