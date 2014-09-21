/**
 * Defines the IComponent interface, which is the base for all components.
 */
module dash.components.component;
import dash.core, dash.components, dash.graphics, dash.utility;

import vibe.data.bson, vibe.data.json, dash.utility.data.yaml;
import std.algorithm, std.array, std.string, std.traits, std.conv, std.typecons;

/// Tests if a type can be created from yaml.
enum isComponent(alias T) = is( T == class ) && is( T : Component ) && !__traits( isAbstractClass, T );
private enum perSerializationFormat( string code ) = "".reduce!( ( working, type ) => working ~ code.replace( "$type", type ) )( serializationFormats );
alias helper( alias T ) = T;
alias helper( T... ) = T;
alias helper() = TypeTuple!();

/**
 * Interface for components to implement.
 */
abstract class Component
{
public:
    /// The GameObject that owns this component.
    @ignore
    GameObject owner;

    /// The function called on initialization of the object.
    void initialize() { }
    /// Called on the update cycle.
    void update() { }
    /// Called on the draw cycle.
    void draw() { }
    /// Called on shutdown.
    void shutdown() { }

    /**
     * Create a description from the this parameter.
     */
    const(Description) description() @property
    {
        assert( typeid(this) in descriptionCreators, "ComponentDescription not found for type " ~ typeid(this).name );
        return descriptionCreators[ typeid(this) ]( this );
    }
    private alias DescriptionCreator = const(Description) function( Component );
    private static DescriptionCreator[ ClassInfo ] descriptionCreators;

    // For serialization.
    mixin( perSerializationFormat!q{
        @ignore static $type delegate( Component )[ ClassInfo ] $typeSerializers;
        @ignore static Component delegate( $type )[ string ] $typeDeserializers;
        $type to$type() const
        {
            return $typeSerializers[ typeid(this) ]( cast()this );
        }
        static Component from$type( $type d )
        {
            if( auto type = "Type" in d )
            {
                if( auto cereal = type.get!string in $typeDeserializers )
                {
                    return ( *cereal )( d );
                }
                else
                {
                    logWarning( "Component's \"Type\" not found: ", type.get!string );
                    return null;
                }
            }
            else
            {
                logWarning( "Component doesn't have \"Type\" field." );
                return null;
            }
        }
        static assert( is$typeSerializable!Component );
    } );
}

/// The description for the component
abstract class Description
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

    abstract immutable(Field[]) fields() const @property;
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
                return serializeTo$type( SerializationDescription.create( cast(T)c ) );
            };
            Component.$typeDeserializers[ T.stringof ] = ( $type node )
            {
                return deserialize$type!( SerializationDescription )( node ).createInstance();
            };
        } );

        Component.descriptionCreators[ typeid(T) ] = &SerializationDescription.create;
    }

    // Generate description
    enum fieldList = getFields();

private:
    // Generate actual struct
    final class SerializationDescription : Description
    {
        pragma( msg, T.stringof ~ "\n" ~ descContents );
        mixin( descContents );

        override immutable(Description.Field[]) fields() const @property
        {
            return fieldList;
        }

        // Create a description from a component.
        static const(SerializationDescription) create( Component comp )
        {
            auto theThing = cast(T)comp;
            auto desc = new SerializationDescription;

            foreach( field; __traits( allMembers, T ) )
            {
                static if( fieldList.map!(f => f.name).canFind( field ) )
                {
                    mixin( "desc."~field~" = theThing."~field~";\n" );
                }
            }

            return desc;
        }

        // Create a component from a description.
        T createInstance()
        {
            T comp = new T;
            foreach( field; __traits( allMembers, T ) )
            {
                static if( fieldList.map!(f => f.name).canFind( field ) )
                {
                    mixin( "comp." ~ field ~ " = this." ~ field ~ ";\n" );
                }
            }
            return comp;
        }
    }

    // Get a list of fields on the type
    Description.Field[] getFields( size_t idx = 0 )( Description.Field[] fields = [] )
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

                    // Get string form of attributes
                    string attributesStr()
                    {
                        string[] attrs;
                        foreach( attr; __traits( getAttributes, member ) )
                        {
                            attrs ~= attr.to!string;
                        }
                        return attrs.join( ", " ).to!string;
                    }

                    // Get required module import name
                    static if( __traits( compiles, moduleName!( typeof( member ) ) ) )
                        enum modName = moduleName!(typeof(member));
                    else
                        enum modName = null;

                    // Generate field
                    enum newField = Description.Field( memberName, fullyQualifiedName!(Unqual!(typeof(member))), attributesStr, modName );
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
        )( "", fieldList );
    } ();
}
