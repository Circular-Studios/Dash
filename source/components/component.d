/**
 * Defines the IComponent interface, which is the base for all components.
 */
module components.component;
import core, components, graphics, utility;

import yaml;
import std.array, std.string, std.traits;

/**
 * Interface for components to implement.
 */
abstract class Component
{
public:
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
    /// Called when refreshing an object.
    void refresh() { }
}

/**
 * A component that can be defined through YAML.
 */
abstract class YamlComponent : Component
{
    /// The node that defined the component.
    mixin( RefGetter!_yaml );

    /// Called when refreshing an object.
    void refresh( Node node ) { }

    this()
    {
        _yaml = Node( YAMLNull() );
    }

private:
    Node _yaml;
}

/**
 * To be placed at the top of any module defining YamlComponents.
 *
 * Params:
 *  modName =           The name of the module to register.
 */
enum registerComponents( string modName ) = q{
    static this()
    {
        import yaml;
        mixin( "import mod = $modName;" );

        // Foreach definition in the module (classes, structs, functions, etc.)
        foreach( member; __traits( allMembers, mod ) )
        {
            // If the we can get the attributes of the definition
            static if( __traits( compiles, __traits( getAttributes, __traits( getMember, mod, member ) ) ) )
            {
                // Iterate over each attribute and try to find a YamlEntry
                foreach( attrib; __traits( getAttributes, __traits( getMember, mod, member ) ) )
                {
                    // If we find one, process it and go to next definition.
                    static if( is( typeof(attrib) == YamlEntry ) )
                    {
                        // If the type has a loader, register it as the create function.
                        if( attrib.loader )
                        {
                            create[ member ] = ( Node node ) => attrib.loader( node.get!string );
                        }
                        else
                        {
                            registerYamlComponent!( mixin( member ) )( attrib.name.length == 0 ? member : attrib.name );
                        }

                        break;
                    }
                }
            }
        }
    }
}.replace( "$modName", modName );

Component delegate( Node )[string] create;

/// DON'T MIND ME
void registerYamlComponent( Base )( string yamlName = "" ) if( is( Base : Component ) )
{
    // If no name specified, use class name.
    if( yamlName == "" )
        yamlName = Base.stringof.split( "." )[ $-1 ];

    // Make sure the type is instantiable
    static if( __traits( compiles, new Base ) )
    {
        // Make a creator function for the type.
        create[ yamlName ] = ( Node node )
        {
            // Create an instance of the class to assign things to.
            Base b = new Base;
            // Set the yaml property so the class has access to the yaml that created it.
            b.yaml = node;

            // Get all members of the class (including inherited ones).
            foreach( memberName; __traits( allMembers, Base ) )
            {
                // If the attributes are gettable.
                static if( __traits( compiles, __traits( getAttributes, __traits( getMember, Base, memberName ) ) ) )
                {
                    // Iterate over each attribute on the member.
                    foreach( attrib; __traits( getAttributes, __traits( getMember, Base, memberName ) ) )
                    {
                        // If it is marked as a field, process.
                        static if( is( typeof(attrib) == Field ) )
                        {
                            string yamlFieldName;
                            // If a name is not specified, use the name of the member.
                            if( attrib.name == "" )
                                yamlFieldName = memberName;
                            else
                                yamlFieldName = attrib.name;

                            // If there's an loader on the field, use that.
                            if( attrib.loader )
                            {
                                static if( is( typeof( mixin( "b." ~ memberName ) ) : Component ) )
                                {
                                    string val;
                                    if( node.tryFind( yamlFieldName, val ) )
                                        mixin( "b." ~ memberName ) = cast(typeof(mixin( "b." ~ memberName )))attrib.loader( val );
                                    else
                                        logDebug( "Failed finding ", yamlFieldName );
                                }
                            }
                            // If the type of the field has a loader, use that.
                            else if( auto loader = typeof( mixin( "b." ~ memberName ) ).stringof in create )
                            {
                                static if( is( typeof( mixin( "b." ~ memberName ) ) : Component ) )
                                {
                                    string val;
                                    if( node.tryFind( yamlFieldName, val ) )
                                        mixin( "b." ~ memberName ) = cast(typeof(mixin( "b." ~ memberName )))( *loader )( val );
                                    else
                                        logDebug( "Failed finding ", yamlFieldName );
                                }
                            }
                            // Else just try to parse the yaml.
                            else
                            {
                                typeof( __traits( getMember, b, memberName ) ) val;
                                if( node.tryFind( yamlFieldName, val ) )
                                    mixin( "b." ~ memberName ) = val;
                                else
                                    logDebug( "Failed finding ", yamlFieldName );
                            }

                            break;
                        }
                        // If the user forgot (), remind them.
                        else static if( is( typeof(attrib == typeof(field) ) ) )
                        {
                            logWarning( "Don't forget () after field on ", memberName );
                        }
                    }
                }
            }

            return b;
        };
    }
}

alias LoaderFunction = Component delegate( string );

/**
 * Meant to be added to components that can be set from YAML.
 * Example:
 * ---
 * @yamlEntry("Test")
 * class Test : YamlComponent
 * {
 *     @field("X")
 *     int x;
 * }
 * ---
 */
YamlEntry yamlEntry( string loader = "null" )( string name = "" )
{
    return YamlEntry( name, mixin( loader ) );
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
 * @yamlEntry("Test")
 * class Test : YamlComponent
 * {
 *     @field("X")
 *     int x;
 * }
 * ---
 */
Field field( string loader = "null" )( string name = "" )
{
    return Field( name, mixin( loader ) );
}

struct YamlEntry
{
    string name;
    LoaderFunction loader;
}

struct Field
{
    string name;
    LoaderFunction loader;
}
