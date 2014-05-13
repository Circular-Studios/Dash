/**
 * Defines the GameObject class, to be subclassed by scripts and instantiated for static objects.
 */
module core.gameobject;
import core, components, graphics, utility;

import yaml;
import gl3n.linalg, gl3n.math;

import std.conv, std.variant, std.array, std.algorithm, std.typecons, std.range;

enum AnonymousName = "__anonymous";

/**
 * Contains flags for all things that could be disabled.
 */
struct ObjectStateFlags
{
    bool updateComponents;
    bool updateBehaviors;
    bool updateChildren;
    bool drawMesh;
    bool drawLight;

    /**
     * Set each member to false.
     */
    void pauseAll()
    {
        foreach( member; __traits(allMembers, ObjectStateFlags) )
            static if( __traits(compiles, __traits(getMember, ObjectStateFlags, member) = false) )
                __traits(getMember, ObjectStateFlags, member) = false;
    }

    /**
     * Set each member to true.
     */
    void resumeAll()
    {
        foreach( member; __traits(allMembers, ObjectStateFlags) )
            static if( __traits(compiles, __traits(getMember, ObjectStateFlags, member) = true) )
                __traits(getMember, ObjectStateFlags, member) = true;
    }
}

/**
 * Manages all components and transform in the world. Can be overridden.
 */
final class GameObject
{
private:
    Transform _transform;
    Material _material;
    Mesh _mesh;
    Animation _animation;
    Light _light;
    Camera _camera;
    GameObject _parent;
    GameObject[] _children;
    Component[TypeInfo] componentList;
    string _name;
    ObjectStateFlags* _stateFlags;
    bool canChangeName;
    Behaviors _behaviors;
    Node _yaml;
    static uint nextId = 1;

package:
    Scene scene;

public:
    /// The current transform of the object.
    mixin( RefGetter!_transform );
    /// The Material belonging to the object.
    mixin( Property!_material );
    /// The Mesh belonging to the object.
    mixin( Property!_mesh );
    /// The animation on the object.
    mixin( Property!_animation );
    /// The light attached to this object.
    mixin( Property!_light );
    /// The camera attached to this object.
    mixin( Property!_camera );
    /// The object that this object belongs to.
    mixin( Property!_parent );
    /// All of the objects which list this as parent
    mixin( Property!_children );
    /// The scripts this object owns.
    mixin( RefGetter!_behaviors );
    /// The yaml node that created the object.
    mixin( RefGetter!_yaml );
    /// The current update settings
    mixin( Property!( _stateFlags, AccessModifier.Public ) );
    /// The name of the object.
    mixin( Getter!_name );
    /// ditto
    mixin( ConditionalSetter!( _name, q{canChangeName}, AccessModifier.Public ) );
    /// The ID of the object.
    immutable uint id;
    /// Allow setting of state flags directly.
    //alias stateFlags this;

    /**
     * Create a GameObject from a Yaml node.
     *
     * Params:
     *  yamlObj =           The YAML node to pull info from.
     *
     * Returns:
     *  A new game object with components and info pulled from yaml.
     */
    static GameObject createFromYaml( Node yamlObj )
    {
        GameObject obj;
        bool foundClassName;
        string prop, className;
        Node innerNode;

        if( yamlObj.tryFind( "InstanceOf", prop ) )
        {
            obj = Prefabs[ prop ].createInstance();
        }
        else
        {
            obj = new GameObject;
        }

        // Set object name
        obj.name = yamlObj[ "Name" ].as!string;

        // Init transform
        if( yamlObj.tryFind( "Transform", innerNode ) )
        {
            vec3 transVec;
            if( innerNode.tryFind( "Scale", transVec ) )
                obj.transform.scale = vec3( transVec );
            if( innerNode.tryFind( "Position", transVec ) )
                obj.transform.position = vec3( transVec );
            if( innerNode.tryFind( "Rotation", transVec ) )
                obj.transform.rotation = quat.identity.rotatex( transVec.x.radians ).rotatey( transVec.y.radians ).rotatez( transVec.z.radians );
        }

        if( yamlObj.tryFind( "Behaviors", innerNode ) )
        {
            if( !innerNode.isSequence )
            {
                logWarning( "Behaviors tag of ", obj.name, " must be a sequence." );
            }
            else
            {
                foreach( Node behavior; innerNode )
                {
                    string className;
                    Node fields;
                    if( !behavior.tryFind( "Class", className ) )
                        logFatal( "Behavior element in ", obj.name, " must have a Class value." );
                    if( !behavior.tryFind( "Fields", fields ) )
                        fields = Node( YAMLNull() );
                    obj.behaviors.createBehavior( className, fields );
                }
            }
        }

        if( yamlObj.tryFind( "Children", innerNode ) )
        {
            if( innerNode.isSequence )
            {
                foreach( Node child; innerNode )
                {
                    // If inline object, create it and add it as a child.
                    if( child.isMapping )
                        obj.addChild( GameObject.createFromYaml( child ) );
                    // Add child name to map.
                    else
                        logWarning( "Specifing child objects by name is deprecated. Please add ", child.get!string, " as an inline child of ", obj.name, "." );
                }
            }
            else
            {
                logWarning( "Scalar values and mappings in 'Children' of ", obj.name, " are not supported, and it is being ignored." );
            }
        }

        // Init components
        foreach( string key, Node componentNode; yamlObj )
        {
            if( key == "Name" || key == "InstanceOf" || key == "Transform" || key == "Children" )
                continue;

            if( auto init = key in create )
            {
                auto newComp = (*init)( componentNode );
                obj.addComponent( newComp );
                newComp.owner = obj;
            }
            else
                logWarning( "Unknown key: ", key );
        }

        //obj.behaviors.onInitialize();
        foreach( comp; obj.componentList )
            comp.initialize();

        return obj;
    }
    /**
     * Create a GameObject from a Yaml node.
     *
     * Params:
     *  fields =            The YAML node to pull info from.
     *
     * Returns:
     *  A tuple of the object created at index 0, and the behavior at index 1.
     */
    static auto createWithBehavior( BehaviorT )( Node fields = Node( YAMLNull() ) )
    {
        auto newObj = new GameObject;

        newObj.behaviors.createBehavior!BehaviorT( fields );

        return tuple( newObj, newObj.behaviors.get!BehaviorT );
    }

    /**
     * Creates basic GameObject with transform and connection to transform's emitter.
     */
    this()
    {
        _transform = Transform( this );
        _behaviors = Behaviors( this );

        // Create default material
        material = new Material( "default" );
        id = nextId++;

        stateFlags = new ObjectStateFlags;
        stateFlags.resumeAll();

        name = typeid(this).name.split( '.' )[ $-1 ] ~ id.to!string;
        canChangeName = true;
    }

    /**
     * Called once per frame to update all children and components.
     */
    final void update()
    {
        /*if( stateFlags.updateBehaviors )
            behaviors.onUpdate();*/

        if( stateFlags.updateComponents )
            foreach( ci, component; componentList )
                component.update();

        if( stateFlags.updateChildren )
            foreach( obj; children )
                obj.update();
    }

    /**
     * Called once per frame to draw all children.
     */
    final void draw()
    {
        //behaviors.onDraw();

        foreach( obj; children )
            obj.draw();
    }

    /**
     * Called when the game is shutting down, to shutdown all children.
     */
    final void shutdown()
    {
        //behaviors.onShutdown();

        foreach( obj; children )
            obj.shutdown();
    }

    /**
     * Refreshes the object with the given YAML node.
     *
     * Params:
     *  node =          The node to refresh the object with.
     */
    final void refresh( Node node )
    {
        /*foreach( string name, Node component; node )
        {
            if( auto refresher = name in IComponent.refreshers )
            {
                ( *refresher )( component, this );
            }
        }*/

        Node yamlChildren;
        if( node.tryFind( "Children", yamlChildren ) && yamlChildren.isSequence )
        {
            auto childNames = children.map!( child => child.name );
            bool[string] childFound = childNames.zip( false.repeat( childNames.length ) ).assocArray();

            foreach( Node yamlChild; yamlChildren )
            {
                // Find 0 based index of child in yamlChildren
                if( auto index = childNames.countUntil( yamlChild[ "Name" ].get!string ) + 1 )
                {
                    // Refresh with YAML node.
                    children[ index - 1 ].refresh( yamlChild );
                    childFound[ yamlChild[ "Name" ].get!string ] = true;
                }
                // If not in children, add it.
                else
                {
                    addChild( GameObject.createFromYaml( yamlChild ) );
                }
            }

            // Filter out found children's names, and then get the objects.
            auto unfoundChildren = childFound.keys
                                        .filter!( name => !childFound[ name ] )
                                        .map!( name => children[ childNames.countUntil( name ) ] );
            foreach( unfound; unfoundChildren )
            {
                logDebug( "Removing child ", unfound.name, " from ", name, "." );
                unfound.shutdown();
                removeChild( unfound );
            }
        }
        // Remove all children
        else
        {
            foreach( child; children )
            {
                child.shutdown();
                removeChild( child );
            }
        }

        //behaviors.onRefresh();   
    }

    /**
     * Adds a component to the object.
     */
    final void addComponent( Component newComponent )
    {
        if( newComponent )
        {
            componentList[ typeid(newComponent) ] = newComponent;

            enum setProperty( string prop ) = q{
                if( typeid(newComponent) == typeid(typeof($prop)) )
                {
                    $prop = cast(typeof($prop))newComponent;
                    return;
                }
            }.replace( "$prop", prop );

            mixin( setProperty!q{_material} );
            mixin( setProperty!q{_camera} );
            mixin( setProperty!q{_animation} );
            if( typeid(newComponent) == typeid(Mesh) )
            {
                _mesh = cast(Mesh)newComponent;

                if( _mesh.animated )
                    addComponent( _mesh.animationData.getComponent() );

                return;
            }
            else if( typeid(newComponent) == typeid(Light) || typeid(newComponent).base == typeid(Light) )
            {
                _light = cast(Light)newComponent;
                return;
            }
        }
    }

    /**
     * Gets a component of the given type.
     */
    final T getComponent( T )() if( is( T : Component ) )
    {
        if( auto comp = typeid(T) in componentList )
            return cast(T)*comp;
        else
            return null;
    }

    /**
     * Adds object to the children, adds it to the scene graph.
     *
     * Params:
     *  newChild =            The object to add.
     */
    final void addChild( GameObject newChild )
    {
        // Nothing to see here.
        if( newChild.parent == this )
            return;
        // Remove from current parent
        else if( newChild.parent )
            newChild.parent.removeChild( newChild );

        _children ~= newChild;
        newChild.parent = this;
        newChild.canChangeName = false;

        // Get root object
        GameObject par;
        for( par = this; par.parent; par = par.parent ) { }

        if( par.scene )
        {
            GameObject[] objectChildren;
            {
                GameObject[] objs;
                objs ~= newChild;

                while( objs.length )
                {
                    auto obj = objs[ 0 ];
                    objs = objs[ 1..$ ];
                    objectChildren ~= obj;

                    foreach( child; obj.children )
                        objs ~= child;
                }
            }

            // If adding to the scene, make sure all new children are in.
            foreach( child; objectChildren )
            {
                par.scene.objectById[ child.id ] = child;
                par.scene.idByName[ child.name ] = child.id;
            }
        }

    }

    /**
     * Removes the given object as a child from this object.
     *
     * Params:
     *  oldChild =            The object to remove.
     */
    final void removeChild( GameObject oldChild )
    {
        children = children.remove( children.countUntil( oldChild ) );

        oldChild.canChangeName = true;
        oldChild.parent = null;

        // Get root object
        GameObject par;
        for( par = this; par.parent; par = par.parent ) { }

        // Remove from scene.
        if( par.scene )
        {
            par.scene.objectById.remove( oldChild.id );
            par.scene.idByName.remove( oldChild.name );
        }
    }
}

/**
 * Handles 3D Transformations for an object.
 * Stores position, rotation, and scale
 * and can generate a World matrix, worldPosition/Rotation (based on parents' transforms)
 * as well as forward, up, and right axes based on rotation
 */
private struct Transform
{
private:
    GameObject _owner;
    vec3 _prevPos;
    quat _prevRot;
    vec3 _prevScale;
    mat4 _matrix;

    /**
     * Default constructor, most often created by GameObjects.
     *
     * Params:
     *  obj =            The object the transform belongs to.
     */
    this( GameObject obj )
    {
        owner = obj;
        position = vec3(0,0,0);
        scale = vec3(1,1,1);
        rotation = quat.identity;
    }

public:
    // these should remain public fields, properties return copies not references
    /// The position of the object in local space.
    vec3 position;
    /// The rotation of the object in local space.
    quat rotation;
    /// The absolute scale of the object. Ignores parent scale.
    vec3 scale;

    /// The object which this belongs to.
    mixin( Property!( _owner, AccessModifier.Public ) );
    /// The world matrix of the transform.
    mixin( Getter!_matrix );
    //mixin( ThisDirtyGetter!( _matrix, updateMatrix ) );

    @disable this();

    /**
     * This returns the object's position relative to the world origin, not the parent.
     *
     * Returns: The object's position relative to the world origin, not the parent.
     */
    final @property vec3 worldPosition() @safe pure nothrow
    {
        if( owner.parent is null )
            return position;
        else
            return (owner.parent.transform.matrix * vec4(position.x,position.y,position.z,1.0f)).xyz;
    }

    /**
     * This returns the object's rotation relative to the world origin, not the parent.
     *
     * Returns: The object's rotation relative to the world origin, not the parent.
     */
    final @property quat worldRotation() @safe pure nothrow
    {
        if( owner.parent is null )
            return rotation;
        else
            return owner.parent.transform.worldRotation * rotation;
    }

    /*
     * Check if current or a parent's matrix needs to be updated.
     * Called automatically when getting matrix.
     *
     * Returns: Whether or not the object is dirty.
     */
    final @property bool isDirty() @safe pure nothrow
    {
        bool result = position != _prevPos ||
                      rotation != _prevRot ||
                      scale != _prevScale;

        return owner.parent ? (result || owner.parent.transform.isDirty()) : result;
    }

    /*
     * Gets the forward axis of the current transform.
     *
     * Returns: The forward axis of the current transform.
     */
    final @property const vec3 forward()
    {
        return vec3( -2 * (rotation.x * rotation.z + rotation.w * rotation.y),
                            -2 * (rotation.y * rotation.z - rotation.w * rotation.x),
                            -1 + 2 * (rotation.x * rotation.x + rotation.y * rotation.y ));
    }
    ///
    unittest
    {
        import std.stdio;
        import gl3n.math;
        writeln( "Dash Transform forward unittest" );

        auto trans = new Transform( null );
        auto forward = vec3( 0.0f, 1.0f, 0.0f );
        trans.rotation.rotatex( 90.radians );
        assert( almost_equal( trans.forward, forward ) );
    }

    /*
     * Gets the up axis of the current transform.
     *
     * Returns: The up axis of the current transform.
     */
    final  @property const vec3 up()
    {
        return vec3( 2 * (rotation.x * rotation.y - rotation.w * rotation.z),
                        1 - 2 * (rotation.x * rotation.x + rotation.z * rotation.z),
                        2 * (rotation.y * rotation.z + rotation.w * rotation.x));
    }
    ///
    unittest
    {
        import std.stdio;
        import gl3n.math;
        writeln( "Dash Transform up unittest" );

        auto trans = new Transform( null );

        auto up = vec3( 0.0f, 0.0f, 1.0f );
        trans.rotation.rotatex( 90.radians );
        assert( almost_equal( trans.up, up ) );
    }

    /*
     * Gets the right axis of the current transform.
     *
     * Returns: The right axis of the current transform.
     */
    final  @property const vec3 right()
    {
        return vec3( 1 - 2 * (rotation.y * rotation.y + rotation.z * rotation.z),
                        2 * (rotation.x * rotation.y + rotation.w * rotation.z),
                        2 * (rotation.x * rotation.z - rotation.w * rotation.y));
    }
    ///
    unittest
    {
        import std.stdio;
        import gl3n.math;
        writeln( "Dash Transform right unittest" );

        auto trans = new Transform( null );

        auto right = vec3( 0.0f, 0.0f, -1.0f );
        trans.rotation.rotatey( 90.radians );
        assert( almost_equal( trans.right, right ) );
    }

    /**
     * Rebuilds the object's matrix.
     */
    final void updateMatrix() @safe pure nothrow
    {
        _prevPos = position;
        _prevRot = rotation;
        _prevScale = scale;

        _matrix = mat4.identity;
        // Scale
        _matrix[ 0 ][ 0 ] = scale.x;
        _matrix[ 1 ][ 1 ] = scale.y;
        _matrix[ 2 ][ 2 ] = scale.z;

        // Rotate
        _matrix = _matrix * rotation.to_matrix!(4,4);

        // Translate
        _matrix[ 0 ][ 3 ] = position.x;
        _matrix[ 1 ][ 3 ] = position.y;
        _matrix[ 2 ][ 3 ] = position.z;

        // include parent objects' transforms
        if( owner.parent )
            _matrix = owner.parent.transform.matrix * _matrix;

        // force children to update to reflect changes to this
        // compensates for children that don't update properly when only parent is dirty
        foreach( child; owner.children )
            child.transform.updateMatrix();
    }
}
