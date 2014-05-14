/**
 * Defines the IComponent interface, which is the base for all components.
 */
module components.component;
import core, components, graphics, utility;

import yaml;
import std.array, std.string, std.traits;

abstract class YamlObject
{
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
                            typeLoaders[ typeid(mixin( member )) ] = attrib.loader;
                            createYamlObject[ member ] = ( Node node ) => attrib.loader( node.get!string );
                        }
                            
                        registerYamlObjects!( mixin( member ) )( attrib.name.length == 0 ? member : attrib.name );

                        break;
                    }
                }
            }
        }
    }
}.replace( "$modName", modName );

YamlObject delegate( Node )[string] createYamlObject;
void delegate( YamlObject, Node )[TypeInfo] refreshYamlObject;

/// DON'T MIND ME
void registerYamlObjects( Base )( string yamlName = "" ) if( is( Base : YamlObject ) )
{
    // If no name specified, use class name.
    if( yamlName == "" )
        yamlName = Base.stringof.split( "." )[ $-1 ];

    refreshYamlObject[ typeid(Base) ] = ( YamlObject comp, Node n )
    {
        auto b = cast(Base)comp;

        // If node contains reference to this type, grab that as root instead.
        Node node;
        if( !n.tryFind( yamlName, node ) )
            node = n;

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
                            static if( is( typeof( mixin( "b." ~ memberName ) ) : YamlObject ) )
                            {
                                string val;
                                if( node.tryFind( yamlFieldName, val ) )
                                {
                                    // If value hasn't changed, ignore.
                                    string oldVal;
                                    if( b.yaml.tryFind( yamlFieldName, oldVal ) )
                                        if( oldVal == val )
                                            continue;

                                    logInfo( "Loading value of ", yamlName, ".", memberName );
                                    mixin( "b." ~ memberName ) = cast(typeof(mixin( "b." ~ memberName )))attrib.loader( val );
                                }
                                else
                                {
                                    logDebug( "Failed finding ", yamlFieldName );
                                }
                            }
                        }
                        // If the type of the field has a loader, use that.
                        else if( auto loader = typeid( mixin( "b." ~ memberName ) ) in typeLoaders )
                        {
                            static if( is( typeof( mixin( "b." ~ memberName ) ) : YamlObject ) )
                            {
                                string val;
                                if( node.tryFind( yamlFieldName, val ) )
                                {
                                    // If value hasn't changed, ignore.
                                    string oldVal;
                                    if( b.yaml.tryFind( yamlFieldName, oldVal ) )
                                        if( oldVal == val )
                                            continue;

                                    logInfo( "Loading value of ", yamlName, ".", memberName );
                                    mixin( "b." ~ memberName ) = cast(typeof(mixin( "b." ~ memberName )))( *loader )( val );
                                }
                                else
                                {
                                    logDebug( "Failed finding ", yamlFieldName );
                                }
                            }
                        }
                        // Else just try to parse the yaml.
                        else
                        {
                            typeof( __traits( getMember, b, memberName ) ) val;
                            if( node.tryFind( yamlFieldName, val ) )
                            {
                                // If value hasn't changed, ignore.
                                typeof( __traits( getMember, b, memberName ) ) oldVal;
                                if( b.yaml.tryFind( yamlFieldName, oldVal ) )
                                    if( oldVal == val )
                                        continue;

                                logInfo( "Loading value of ", yamlName, ".", memberName );
                                mixin( "b." ~ memberName ) = val;
                            }
                            else
                            {
                                logDebug( "Failed finding ", yamlFieldName );
                            }
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

        // Set the yaml property so the class has access to the yaml that created it.
        b.yaml = node;
    };

    // Make sure the type is instantiable
    static if( __traits( compiles, new Base ) )
    {
        // Make a creator function for the type.
        createYamlObject[ yamlName ] = ( Node node )
        {
            // Create an instance of the class to assign things to.
            Base b = new Base;

            refreshYamlObject[ typeid(Base) ]( b, node );          

            return b;
        };
    }
}

alias LoaderFunction = YamlObject delegate( string );

/**
 * Meant to be added to components that can be set from YAML.
 * Example:
 * ---
 * @yamlEntry("Test")
 * class Test : Component
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
 * class Test : Component
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

LoaderFunction[TypeInfo] typeLoaders;

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
