/**
 * Defines the IComponent interface, which is the base for all components.
 */
module dash.components.component;
import dash.core, dash.components, dash.graphics, dash.utility;

import yaml;
import std.array, std.string, std.traits, std.conv;

/// Tests if a type can be created from yaml.
enum isYamlObject(T) = __traits( compiles, { T obj; obj.yaml = Node( YAMLNull() ); } );

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
auto field( string loader = "null" )( string name = "" )
{
    return YamlUDA( YamlType.Field, name, mixin( loader ) );
}

/// Used to create objects from yaml. The key is the YAML name of the type.
Object delegate( Node )[string] createYamlObject;
/// Used to create components from yaml. The key is the YAML name of the type.
Component delegate( Node )[string] createYamlComponent;
/// Refresh any object defined from yaml. The key is the typeid of the type.
void delegate( Object, Node )[TypeInfo] refreshYamlObject;

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
                    static if( is( typeof(attrib) == YamlUDA ) )
                    {
                        if( attrib.type == YamlType.Component )
                        {
                            /*static if( !is( typeof( mixin( member ) ) : Component ) )
                                logError( "@yamlComponent() must be placed on a class which extends Component. ", member, " fails this check." );*/

                            // If the type has a loader, register it as the create function.
                            if( attrib.loader )
                            {
                                typeLoaders[ typeid(mixin( member )) ] = attrib.loader;
                                createYamlComponent[ member ] = ( node ) { if( node.isScalar ) return cast(Component)attrib.loader( node.get!string ); else { logInfo( "Invalid node for ", member ); return null; } };
                            }
                        }
                        else if( attrib.type == YamlType.Object )
                        {
                            /*static if( !is( typeof( mixin( member ) ) : YamlObject ) && !isYamlObject!( mixin( member ) ) )
                                logError( "@yamlObject() must be placed on a class which extends YamlObject or passes isYamlObject. ", member, " fails this check." );*/
                        }
                        else
                        {
                            logError( "@field on a type is illegal." );
                        }

                        registerYamlObjects!( mixin( member ) )( attrib.name.length == 0 ? member : attrib.name, attrib.type );
                    }
                }
            }
        }
    }
}.replace( "$modName", modName );

/// For internal use only.
LoaderFunction[TypeInfo] typeLoaders;

/// DON'T MIND ME
void registerYamlObjects( Base )( string yamlName, YamlType type ) if( isYamlObject!Base )
{
    // If no name specified, use class name.
    if( yamlName == "" )
        yamlName = Base.stringof.split( "." )[ $-1 ];

    refreshYamlObject[ typeid(Base) ] = ( comp, n )
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
                    static if( is( typeof(attrib) == YamlUDA ) )
                    {
                        if( attrib.type == YamlType.Field )
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
                                    string newStringVal;
                                    if( node.tryFind( yamlFieldName, newStringVal ) )
                                    {
                                        auto newVal = cast(typeof(mixin( "b." ~ memberName )))attrib.loader( newStringVal );
                                        // If value hasn't changed, or if it was changed through code, ignore.
                                        string oldStringVal;
                                        if( b.yaml.tryFind( yamlFieldName, oldStringVal ) )
                                        {
                                            auto oldVal = cast(typeof(mixin( "b." ~ memberName )))attrib.loader( oldStringVal );
                                            if( oldStringVal == newStringVal || oldVal != mixin( "b." ~ memberName ) )
                                                continue;
                                        }

                                        mixin( "b." ~ memberName ) = newVal;
                                    }
                                    else
                                    {
                                        logDebug( "Failed using attrib loader for ", yamlFieldName );
                                    }
                                }
                            }
                            // If the type of the field has a loader, use that.
                            else if( typeid( mixin( "b." ~ memberName ) ) in typeLoaders )
                            {
                                static if( is( typeof( mixin( "b." ~ memberName ) ) : YamlObject ) )
                                {
                                    auto loader = typeid( mixin( "b." ~ memberName ) ) in typeLoaders;

                                    string newStringVal;
                                    if( node.tryFind( yamlFieldName, newStringVal ) )
                                    {
                                        auto newVal = cast(typeof(mixin( "b." ~ memberName )))( *loader )( newStringVal );
                                        // If value hasn't changed, ignore.
                                        string oldStringVal;
                                        if( b.yaml.tryFind( yamlFieldName, oldStringVal ) )
                                        {
                                            auto oldVal = cast(typeof(mixin( "b." ~ memberName )))( *loader )( oldStringVal );
                                            if( oldStringVal == newStringVal || oldVal != mixin( "b." ~ memberName ) )
                                                continue;
                                        }

                                        mixin( "b." ~ memberName ) = newVal;
                                    }
                                    else
                                    {
                                        logDebug( "Failed using typeloader for ", yamlFieldName );
                                    }
                                }
                            }
                            // Else just try to parse the yaml.
                            else
                            {
                                typeof( __traits( getMember, b, memberName ) ) val;

                                static if( is( typeof( __traits( getMember, b, memberName ) ) == enum ) )
                                {
                                    string valName;
                                    bool result = node.tryFind( yamlFieldName, valName );

                                    if( result )
                                        val = valName.to!( typeof( mixin( "b." ~ memberName ) ) );
                                }
                                else
                                {
                                    bool result = node.tryFind( yamlFieldName, val );
                                }

                                if( result )
                                {
                                    // If value hasn't changed, ignore.
                                    typeof( __traits( getMember, b, memberName ) ) oldVal;
                                    if( b.yaml.tryFind( yamlFieldName, oldVal ) )
                                    {
                                        if( oldVal == val || oldVal != mixin( "b." ~ memberName ) )
                                            continue;
                                    }

                                    mixin( "b." ~ memberName ) = val;
                                }
                                else
                                {
                                    logDebug( "Failed creating ", yamlFieldName, " of type ", typeof( mixin( "b." ~ memberName ) ).stringof );
                                    logDebug( "Typeloaders: ", typeLoaders );
                                }
                            }
                        }

                        break;
                    }
                    // If the user forgot (), remind them.
                    else static if( is( typeof(attrib == typeof(field) ) ) )
                    {
                        static assert( false, "Don't forget () after field on " ~ memberName );
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
        static if( is( Base : Component ) )
        {
            if( type == YamlType.Component )
            {
                if( auto loader = typeid( Base ) in typeLoaders )
                {
                    createYamlComponent[ yamlName ] = ( node )
                    {
                        return cast(Component)( *loader )( node.get!string );
                    };
                }
                else
                {
                    createYamlComponent[ yamlName ] = ( node )
                    {
                        // Create an instance of the class to assign things to.
                        Component b = new Base;

                        refreshYamlObject[ typeid(Base) ]( b, node );

                        return b;
                    };
                }
            }
        }
        if( type == YamlType.Object )
        {
            createYamlObject[ yamlName ] = ( node )
            {
                // Create an instance of the class to assign things to.
                Object b = new Base;

                refreshYamlObject[ typeid(Base) ]( b, node );

                return b;
            };
        }
    }
}

enum YamlType { Object, Component, Field }
private alias LoaderFunction = YamlObject delegate( string );

struct YamlUDA
{
    YamlType type;
    string name;
    LoaderFunction loader;
}
