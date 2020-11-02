/**
 * Defines the IComponent interface, which is the base for all components.
 */
module dash.components.component;
import dash.core, dash.components, dash.graphics, dash.utility;

import vibe.data.bson, vibe.data.json, dash.utility.data.yaml;
import std.algorithm, std.array, std.string, std.traits, std.conv, std.typecons;

/// Tests if a type can be created from yaml.
enum isComponent(alias T) = is( T == class ) && is( T : Component ) && !__traits( isAbstractClass, T );
private enum perSerializationFormat( string code ) = "".reduce!( ( working, type ) => working ~ code.replace( "$type", type ) )( serializationModeNames );
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
        assert( getDescriptionFactory( typeid(this) ), "No description found for type: " ~ typeid(this).name );
    }
    body
    {
        return getDescriptionFactory( typeid(this) ).fromComponent( this );
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
private Rebindable!( immutable DescriptionFactory )[ClassInfo] descriptionsByClassInfo;
private Rebindable!( immutable DescriptionFactory )[string] descriptionsByName;

immutable(DescriptionFactory) getDescriptionFactory( ClassInfo type )
{
    return descriptionsByClassInfo.get( type, Rebindable!( immutable DescriptionFactory )( null ) );
}

immutable(DescriptionFactory) getDescriptionFactory( string name )
{
    return descriptionsByName.get( name, Rebindable!( immutable DescriptionFactory )( null ) );
}

/// The description for the component
abstract class Description
{
public:
    /// The type of the component.
    @rename( "Type" )
    string type;

    /// Create an instance of the component the description is for.
    abstract Component instantiate() const;

    /// Refresh a component by comparing descriptions.
    abstract void refresh( Component comp, const Description newDesc );

    /// Get the type of the component the description is for.
    @ignore
    abstract ClassInfo componentType() @property const;

    /// Serializers and deserializers
    mixin( perSerializationFormat!q{
        // Serializers for vibe
        abstract $type to$type() const;
        static Description from$type( $type data )
        {
            // If it's Bson, convert it to a json object.
            static if( is( $type == Bson ) )
                auto d = data.toJson();
            else
                auto d = data;

            if( auto type = "Type" in d )
            {
                if( auto desc = getDescriptionFactory( type.get!string ) )
                {
                    DataContainer cont;
                    cont = data;
                    return desc.fromData(cont);
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
        // static assert( is$typeSerializable!Description );
    } );
}

/**
 * A Factory that creates descriptions for a Component type.
 * Sub-classes are automatically generated per Component type.
 * There should only be one instance per Component type.
 */
abstract class DescriptionFactory
{
public:
    /// Get the type of the component the description is for.
    abstract ClassInfo componentType() @property const;

    /// Creates a description from a data represenetation;
    abstract Description fromData(const DataContainer data) const;

    /// Creates a description from a component.
    abstract Description fromComponent(const Component comp) const;
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
        immutable desc = new immutable TemplatedDescriptionFactory;
        descriptionsByClassInfo[ typeid(T) ] = desc;
        descriptionsByName[ name ] = desc;
    }

    /// The size of an instance of the component.
    enum instanceSize = __traits( classInstanceSize, T );

    /// The name of the component.
    enum name = __traits( identifier, T );

private:
    enum defaultSerializationMode = SerializationMode.Json;

    /**
     * Generate actual description of a component.
     *
     * Contains:
     *  * A represenetation of each field on the component at root level.
     *  * A list of the fields ($(D fields)).
     *  * A method to create a description from an instance of a component ($(D fromComponent)).
     *  * A method to refresh an instance of the component with a newer description ($(D refresh)).
     *  * A method to create an instance of the component ($(D instantiate)).
     *  * The ClassInfo of the component ($(D componentType)).
     */
    final class TemplatedDescription : Description
    {
    public:
        DataContainer represenetation;

        this(DataContainer represenetation_)
        {
            represenetation = represenetation_;
        }

        /// Refresh a component by comparing descriptions.
        override void refresh( Component comp, const Description desc )
        in
        {
            assert( cast(T)comp, "Component of the wrong type passed to the wrong description." );
            assert( cast(TemplatedDescription)desc, "Invalid description type." );
        }
        body
        {
            // #TODO
        }

        /// Create a component from a description.
        override T instantiate() const
        {
            T comp;
            mixin(perSerializationFormat!q{
                if (auto data = represenetation.peek!$type)
                {
                    comp = deserialize$type!(T)(cast()*data);
                }
            });
            return comp;
        }

        /// Get the type of the component the description is for.
        override ClassInfo componentType() @property const
        {
            return typeid(T);
        }

        mixin(perSerializationFormat!q{
            override $type to$type() const
            {
                if(auto desc = represenetation.peek!$type())
                {
                    // Return a copy of the represenetation
                    return *desc;
                }
                else
                {
                    errorf("Description not stored as $type.");
                    return $type();   
                }
            }
        });
    } // TemplatedDescription

    final class TemplatedDescriptionFactory : DescriptionFactory
    {
    public:
        /// Get the type of the component the description is for.
        override ClassInfo componentType() @property const
        {
            return typeid(T);
        }

        /// Creates a description from a data represenetation;
        override TemplatedDescription fromData(const DataContainer data) const
        {
            return new TemplatedDescription(data);
        }

        /// Create a description from a component.
        override TemplatedDescription fromComponent(const Component comp) const
        in
        {
            assert(cast(T)comp, "Component instance passed in is of type "~typeid(comp).name~", not "~name);
        }
        body
        {
            mixin(q{alias serFun = serializeTo}~defaultSerializationMode.to!string~";");

            TemplatedDescription desc;
            desc.represenetation = serFun(comp);
            return desc;
        }
    } // TemplatedDescriptionFactory
}
