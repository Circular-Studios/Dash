/**
 * Defines the IComponent interface, which is the base for all components.
 */
module dash.components.component;
import dash.core, dash.components, dash.graphics, dash.utility;

import yaml;
import std.algorithm, std.array, std.string, std.traits, std.conv, std.typecons;

/// Tests if a type can be created from yaml.
enum isYamlObject(T) = __traits( compiles, { T obj; obj.yaml = Node( YAMLNull() ); } );
enum serializationFormats = tuple( "Json", "Bson"/*, "Yaml"*/ );

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
    @ignore
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
    import vibe.data.bson, vibe.data.json, dash.utility.data.yaml;
    mixin( {
        return "".reduce!( ( working, type ) => working ~ q{
            static $type delegate( Component )[ ClassInfo ] $typeSerializers;
            $type to$type() const
            {
                return $typeSerializers[ typeid(this) ]( cast()this );
            }
            static Component from$type( $type d )
            {
                return null;
            }
        }.replace( "$type", type ) )( serializationFormats );
    } () );
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
        import vibe.data.bson, vibe.data.json, dash.utility.data.yaml;
        import mod = $modName;
        alias helper( alias T ) = T;

        // Foreach definition in the module (classes, structs, functions, etc.)
        foreach( memberName; __traits( allMembers, mod ) )
        {
            // Alais to the member
            alias member = helper!( __traits( getMember, mod, memberName ) );

            // If member is a class that extends Componen
            static if( is( member == class ) && is( member : Component ) && !__traits( isAbstractClass, member ) )
            {
                mixin( {
                    import std.string: replace;
                    import std.algorithm: reduce;

                    return "".reduce!( ( working, type ) => working ~ q{
                        Component.$typeSerializers[ typeid(member) ] = ( Component c )
                        {
                            return $type();
                        };
                    }.replace( "$type", type ) )( serializationFormats );
                } () );
            }
        }
    }
}.replace( "$modName", modName );

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
YamlObject delegate( Node )[string] createYamlObject;
/// Used to create components from yaml. The key is the YAML name of the type.
Component delegate( Node )[string] createYamlComponent;
/// Refresh any object defined from yaml. The key is the typeid of the type.
void delegate( YamlObject, Node )[TypeInfo] refreshYamlObject;

enum YamlType { Object, Component, Field }
private alias LoaderFunction = YamlObject delegate( string );

struct YamlUDA
{
    YamlType type;
    string name;
    LoaderFunction loader;
}
