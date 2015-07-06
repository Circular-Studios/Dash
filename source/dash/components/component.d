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

template isSerializableField( alias field )
{
    import vibe.internal.meta.uda;

public:
    enum isSerializableField =
        !isSomeFunction!field &&
        isMutable!fieldType &&
        !findFirstUDA!( IgnoreAttribute, field ).found;

private:
    alias fieldType = typeof(field);
}

/**
 * Interface for components to implement.
 */
abstract class Component
{
private:
    /// The description from the last creation/refresh.
    @ignore
    Description lastDesc;

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
    final const(Description) description() @property
    in
    {
        assert( getDescription( typeid(this) ), "No description found for type: " ~ typeid(this).name );
    }
    body
    {
        return getDescription( typeid(this) ).fromComponent( this );
    }

    /**
     * Refresh an object with a new description
     */
    final void refresh( Description desc )
    {
        lastDesc.refresh( this, desc );
    }

    /// For easy external access
    alias Description = .Description;
}

/**
 * A self-registering component.
 * Useful for when you receive circular dependency errors.
 * Recommended for use only when extending Component directly.
 *
 * Params:
 *  BaseType =          The type being registered.
 *
 * Examples:
 * ---
 * class MyComponent : ComponentReg!MyComponent
 * {
 *     // ...
 * }
 * ---
 */
abstract class ComponentReg( BaseType ) : Component
{
    static this()
    {
        componentMetadata!(Unqual!(BaseType)).register();
    }
}

/// A map of all registered Component types to their descriptions
private Rebindable!( immutable Description )[ClassInfo] descriptionsByClassInfo;
private Rebindable!( immutable Description )[string] descriptionsByName;

immutable(Description) getDescription( ClassInfo type )
{
    return descriptionsByClassInfo.get( type, Rebindable!( immutable Description )( null ) );
}

immutable(Description) getDescription( string name )
{
    return descriptionsByName.get( name, Rebindable!( immutable Description )( null ) );
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
    @ignore
    abstract immutable(Field[]) fields() @property const;

    /// Create an instance of the component the description is for.
    abstract Component createInstance() const;

    /// Refresh a component by comparing descriptions.
    abstract void refresh( Component comp, const Description newDesc );

    /// Creates a description from a component.
    abstract const(Description) fromComponent( const Component comp ) const;

    /// Get the type of the component the description is for.
    @ignore
    abstract ClassInfo componentType() @property const;

    /// Serializers and deserializers
    mixin( perSerializationFormat!q{
        // Overridable serializers
        abstract $type serializeDescriptionTo$type( Description c ) const;
        abstract Description deserializeFrom$type( $type node ) const;

         // Serializers for vibe
        final $type to$type() const
        {
            if( auto desc = getDescription( componentType ) )
            {
                return desc.serializeDescriptionTo$type( cast()this );
            }
            else
            {
                errorf( "Description of type %s not found! Did you forget a mixin(registerComponents!())?", typeid(this).name );
                return $type();
            }
        }
        static Description from$type( $type data )
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
                    return desc.deserializeFrom$type( data );
                }
                else
                {
                    warningf( "Component's \"Type\" not found: %s", type.get!string );
                    return null;
                }
            }
            else
            {
                warningf( "Component doesn't have \"Type\" field." );
                return null;
            }
        }
        static assert( is$typeSerializable!Description );
    } );
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
        foreach( memberName; __traits( allMembers, mod ) ) static if( __traits( compiles, __traits( getMember, mod, memberName ) ) )
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
    /// Runtime function, registers serializers.
    void register()
    {
        immutable desc = new immutable SerializationDescription;
        descriptionsByClassInfo[ typeid(T) ] = desc;
        descriptionsByName[ name ] = desc;
    }

    /// A list of fields on the component.
    enum fieldList = getFields();

    /// The size of an instance of the component.
    enum instanceSize = __traits( classInstanceSize, T );

    /// The name of the component.
    enum name = __traits( identifier, T );

private:
    /**
     * Generate actual description of a component.
     *
     * Contains:
     *  * A represenetation of each field on the component at root level.
     *  * A list of the fields ($(D fields)).
     *  * A method to create a description from an instance of a component ($(D fromComponent)).
     *  * A method to refresh an instance of the component with a newer description ($(D refresh)).
     *  * A method to create an instance of the component ($(D createInstance)).
     *  * The ClassInfo of the component ($(D componentType)).
     */
    final class SerializationDescription : Description
    {
        mixin( { return reduce!( ( working, field ) {
            // Append required import for variable type
            if( field.mod )         working ~= "import " ~ field.mod ~ ";\n";
            // Append variable attributes
            if( field.attributes )  working ~= "@(" ~ field.attributes ~ ")\n";
            // Append variable declaration
            return working ~ field.typeName ~ " " ~ field.name ~ ";\n";
        } )( "", fieldList ); } () );

        // Generate serializers for the type
        mixin( perSerializationFormat!q{
            override $type serializeDescriptionTo$type( Description desc ) const
            {
                return serializeTo$type( cast(SerializationDescription)desc );
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
        override const(SerializationDescription) fromComponent( const Component comp ) const
        {
            auto theThing = cast(T)comp;
            auto desc = new SerializationDescription;
            desc.type = name;

            foreach( fieldName; __traits( allMembers, T ) )
            {
                enum idx = fieldList.map!(f => f.name).countUntil( fieldName );
                static if( idx >= 0 )
                {
                    enum field = fieldList[ idx ];
                    // Serialize the value for the description
                    mixin( "auto ser = "~field.serializer~".serialize(theThing."~field.name~");" );
                    // Copy the value to the description
                    mixin( "desc."~field.name~" = ser;" );
                }
            }

            return desc;
        }

        /// Refresh a component by comparing descriptions.
        override void refresh( Component comp, const Description desc )
        in
        {
            assert( cast(T)comp, "Component of the wrong type passed to the wrong description." );
            assert( cast(SerializationDescription)desc, "Invalid description type." );
        }
        body
        {
            auto t = cast(T)comp;
            auto newDesc = cast(SerializationDescription)desc;

            foreach( fieldName; __traits( allMembers, T ) )
            {
                enum idx = fieldList.map!(f => f.name).countUntil( fieldName );
                static if( idx >= 0 )
                {
                    enum field = fieldList[ idx ];
                    // Check if the field was actually changed, and that it hasn't changed on component
                    if( mixin( field.name ) == mixin( "newDesc." ~ field.name ) )
                    {
                        // Copy the value into this description
                        mixin( "this."~field.name~" = newDesc."~field.name~";" );
                        // Deserialize it for the component
                        mixin( "auto ser = "~field.serializer~".deserialize(newDesc."~field.name~");" );
                        // Copy the new value to the component
                        mixin( "t."~field.name~" = ser;" );
                    }
                }
            }
        }

        /// Create a component from a description.
        override T createInstance() const
        {
            T comp = new T;
            comp.lastDesc = cast()this;

            foreach( fieldName; __traits( allMembers, T ) )
            {
                enum idx = fieldList.map!(f => f.name).countUntil( fieldName );
                static if( idx >= 0 )
                {
                    enum field = fieldList[ idx ];
                    // Check if the field was actually set
                    if( mixin( field.name ) != mixin( "new SerializationDescription()." ~ field.name ) )
                    {
                        // Deserialize it for the component
                        mixin( "auto rep = cast("~field.serializer~".Rep)this."~field.name~";" );
                        mixin( "auto ser = "~field.serializer~".deserialize(rep);" );
                        mixin( "comp."~field.name~" = ser;" );
                    }
                }
            }
            return comp;
        }

        /// Get the type of the component the description is for.
        override ClassInfo componentType() @property const
        {
            return typeid(T);
        }
    } // SerializationDescription

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
                alias member = helper!( __traits( getMember, T, memberName ) );
                alias memberType = typeof(member);

                // Process variables
                static if( isSerializableField!member )
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

                    template SerializedType( T )
                    {
                        static if( is( T U : U[] ) )
                            alias SerializedType = SerializedType!U;
                        else
                            alias SerializedType = T;
                    }

                    // Get required module import name
                    static if( __traits( compiles, moduleName!( SerializedType!memberType ) ) )
                        enum modName = moduleName!( SerializedType!memberType );
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
