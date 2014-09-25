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
        $type to$type() const
        {
            return getDescription( typeid(this) ).serializeComponentTo$type( cast()this );
        }
        static Component from$type( $type data )
        {
            // If it's Bson, convert it to a json object.
            static if( is( $type == Bson ) )
                auto d = data.toJson();
            else
                auto d = data;

            if( auto type = "Type" in d )
            {
                if( auto desc = getDescription( type.get!string ) )
                {
                    return desc.deserializeFrom$type( data ).createInstance();
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
        string serializer;
    }

    /// The type of the component.
    @rename( "Type" )
    string type;

    /// Get a list of teh fields on a component.
    abstract immutable(Field[]) fields() const @property;

    /// Create an instance of the component the description is for.
    abstract Component createInstance() const;

    /// Serializers and deserializers
    mixin( perSerializationFormat!q{
        abstract $type serializeComponentTo$type( Component c ) const;
        abstract Description deserializeFrom$type( $type node ) const;
    } );
}

/// A map of all registered Component types to their descriptions
private immutable(Description)[ClassInfo] descriptionsByClassInfo;
private immutable(Description)[string] descriptionsByName;

immutable(Description) getDescription( ClassInfo type )
{
    if( auto desc = type in descriptionsByClassInfo )
        return *desc;
    else
        return null;
}

immutable(Description) getDescription( string name )
{
    if( auto desc = name in descriptionsByName )
        return *desc;
    else
        return null;
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
        immutable desc = new immutable SerializationDescription;
        descriptionsByClassInfo[ typeid(T) ] = desc;
        descriptionsByName[ T.stringof ] = desc;
    }

    // Generate description
    enum fieldList = getFields();

private:
    // Generate actual struct
    final class SerializationDescription : Description
    {
        mixin( { return reduce!( ( working, field ) {
            string result = working;

            // Append required import for variable type
            if( field.mod )
                result ~= "import " ~ field.mod ~ ";\n";

            // Append variable attributes
            if( field.attributes )
                result ~= "@(" ~ field.attributes ~ ")\n";

            // Append variable declaration
            result ~= field.typeName ~ " " ~ field.name ~ ";\n";

            return result;
        } )( "", fieldList ); } () );

        // Generate serializers for the type
        mixin( perSerializationFormat!q{
            override $type serializeComponentTo$type( Component c ) const
            {
                return serializeTo$type( SerializationDescription.create( cast(T)c ) );
            }
            override SerializationDescription deserializeFrom$type( $type node ) const
            {
                return deserialize$type!SerializationDescription( node );
            }
        } );

        /// Get a list of field descriptions
        override immutable(Description.Field[]) fields() const @property
        {
            return fieldList;
        }

        /// Create a description from a component.
        static const(SerializationDescription) create( Component comp )
        {
            auto theThing = cast(T)comp;
            auto desc = new SerializationDescription;
            desc.type = T.stringof;

            foreach( fieldName; __traits( allMembers, T ) )
            {
                enum idx = fieldList.map!(f => f.name).countUntil( fieldName );
                static if( idx >= 0 )
                {
                    enum field = fieldList[ idx ];
                    mixin( "auto ser = "~field.serializer~".serialize(theThing."~field.name~");" );
                    mixin( "desc."~field.name~" = ser;" );
                }
            }

            return desc;
        }

        /// Create a component from a description.
        override T createInstance() const
        {
            T comp = new T;
            foreach( fieldName; __traits( allMembers, T ) )
            {
                enum idx = fieldList.map!(f => f.name).countUntil( fieldName );
                static if( idx >= 0 )
                {
                    enum field = fieldList[ idx ];
                    // Check if the field was actually set
                    if( mixin( field.name ) != mixin( "new SerializationDescription()." ~ field.name ) )
                    {
                        mixin( "auto ser = "~field.serializer~".deserialize(this."~field.name~");" );
                        mixin( "comp."~field.name~" = ser;" );
                    }
                }
            }
            return comp;
        }
    }

    /// Get a list of fields on the type
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
                import vibe.internal.meta.uda;

                alias member = helper!( __traits( getMember, T, memberName ) );
                alias memberType = typeof(member);

                // Process variables
                static if( !isSomeFunction!member && !findFirstUDA!( IgnoreAttribute, member ).found )
                {
                    // Get string form of attributes
                    string attributesStr()
                    {
                        import std.conv;
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

                    // Get the serializer for the type
                    alias serializer = serializerFor!memberType;
                    alias descMemberType = serializer.Rep;
                    // Generate field
                    return getFields!( idx + 1 )( fields ~
                        Description.Field(
                            memberName,
                            fullyQualifiedName!(Unqual!descMemberType),
                            attributesStr,
                            modName,
                            serializer.stringof
                        )
                    );
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
}
