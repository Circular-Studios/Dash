/**
 * Defines the GameObject class, to be subclassed by scripts and instantiated for static objects.
 */
module dash.core.gameobject;
import dash.core, dash.components, dash.graphics, dash.utility;

import yaml;
import std.conv, std.variant, std.array, std.algorithm, std.typecons, std.range, std.string, std.math;

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

/// A tuple of a resource and a gameobject reference
alias GameObjectResource = Tuple!( Resource, "resource", GameObject, "object" );
GameObjectResource[][Resource] objectsByResource;

/**
 * Manages all components and transform in the world. Can be overridden.
 */
final class GameObject
{
private:
    GameObject _parent;
    GameObject[] _children;
    Prefab _prefab;
    Component[ClassInfo] componentList;
    string _name;
    bool canChangeName;
    static uint nextId = 1;

    enum componentProperty( Type ) = q{
        @property $type $property() { return getComponent!$type; }
        @property void $property( $type v ) { addComponent( v ); }
    }.replaceMap( [ "$property": Type.stringof.toLower, "$type": Type.stringof ] );

package:
    /// THIS IS ONLY SET IF THIS OBJECT IS SCENE _ROOT
    Scene scene;

    /// Searche the parent tree until we find the scene object
    Scene findScene()
    {
        // Get root object
        GameObject par;
        for( par = this; par.parent; par = par.parent ) { }
        
        return par.scene;
    }

public:
    /**
     * The struct that will be directly deserialized from the ddl.
     */
    static struct Description
    {
        /// The name of the object.
        @rename( "Name" )
        string name;

        /// The name of the prefab to create from. Do you use with $(D prefab).
        @rename( "InstanceOf" ) @optional
        string prefabName = null;

        /// The Prefab to create from.
        @ignore
        Prefab prefab;

        /// The transform of the object.
        @rename( "Transform" ) @optional
        Transform.Description transform;

        /// Children of this object.
        @rename( "Children" ) @optional
        Description[] children;

        @rename( "Components" ) @optional
        Component.Description[] components;
    }

    /// The current transform of the object.
    Transform transform;
    /// The light attached to this object.
    @property void light( Light v ) { addComponent( v ); }
    /// ditto
    @property Light light()
    {
        enum get( Type ) = q{
            if( auto l = getComponent!$type )
                return l;
        }.replace( "$type", Type.stringof );
        mixin( get!AmbientLight );
        mixin( get!DirectionalLight );
        mixin( get!PointLight );
        mixin( get!SpotLight );
        return null;
    }
    /// The Mesh belonging to the object.
    mixin( componentProperty!Mesh );
    /// The Material belonging to the object.
    mixin( componentProperty!Material );
    /// The animation on the object.
    mixin( componentProperty!Animation );
    /// The camera attached to this object.
    mixin( componentProperty!Camera );
    /// The emitter attached to this object.
    mixin( componentProperty!Emitter );
    /// The object that this object belongs to.
    mixin( Property!_parent );
    /// All of the objects which list this as parent
    mixin( Property!_children );
    /// The prefab that this object is based on.
    mixin( Property!_prefab );
    /// The name of the object.
    mixin( Property!( _name, AccessModifier.Package ) );
    /// Change the name of the object.
    void changeName( string newName )
    in
    {
        assert( newName && newName.length, "Invalid name given." );
    }
    body
    {
        // Ignore an unchanging name.
        if( name == newName )
        {
            return;
        }
        else if( canChangeName || DGame.instance.currentState == EngineState.Editor )
        {
            // Update mappings in the scene.
            if( auto scene = findScene() )
            {
                scene.idByName.remove( name );
                scene.idByName[ newName ] = id;
            }

            // Change the name.
            name = newName;
        }
        else
        {
            throw new Exception( "Unable to rename gameobject at this time." );
        }
    }
    /// The ID of the object.
    immutable uint id;
    /// The current update settings
    ObjectStateFlags* stateFlags;
    /// Allow setting of state flags directly.
    //alias stateFlags this;

    /**
     * Create a GameObject from a description object.
     *
     * Params:
     *  desc =              The description to pull info from.
     *
     * Returns:
     *  A new game object with components and info pulled from desc.
     */
    static GameObject create( const Description desc )
    {
        GameObject obj;

        // Create the object
        if( desc.prefabName )
        {
            auto fab = Prefabs[ desc.prefabName ];
            obj = fab.createInstance();
            obj.prefab = fab;
        }
        else if( desc.prefab )
        {
            obj = desc.prefab.createInstance();
        }
        else
        {
            obj = new GameObject;
        }

        // Set object name
        obj.name = desc.name;

        // Init transform
        obj.transform = desc.transform;

        // Create children
        if( desc.children.length > 0 )
        {
            foreach( child; desc.children )
            {
                obj.addChild( GameObject.create( child ) );
            }
        }

        // Add components
        foreach( component; desc.components )
        {
            obj.addComponent( component.createInstance() );
        }

        // Init components
        foreach( comp; obj.componentList )
            comp.initialize();

        return obj;
    }

    /**
     * Create a description from a GameObject.
     *
     * Returns:
     *  A new description with components and info.
     */
    Description toDescription()
    {
        Description desc;
        desc.name = name;
        desc.prefab = prefab;
        desc.prefabName = prefab ? prefab.name : null;
        desc.transform = transform.toDescription();
        desc.children = children.map!( child => child.toDescription() ).array();
        desc.components = componentList.values.map!( comp => cast()comp.description ).array();
        return desc;
    }

    /// To complement the descriptions, and make serialization easier.
    static GameObject fromRepresentation( Description desc )
    {
        return GameObject.create( desc );
    }
    /// ditto
    Description toRepresentation()
    {
        return toDescription();
    }
    static assert( isCustomSerializable!GameObject );

    /**
     * Creates basic GameObject with transform and connection to transform's emitter.
     */
    this()
    {
        transform = Transform( this );

        // Create default material
        material = new Material( new MaterialAsset( "default" ) );
        id = nextId++;

        stateFlags = new ObjectStateFlags;
        stateFlags.resumeAll();

        name = typeid(this).name.split( '.' )[ $-1 ] ~ id.to!string;
        canChangeName = true;
    }

    /**
     * Allows you to create an object with a set list of components you already have.
     *
     * Params:
     *  newComponents =     The list of components to add.
     */
    this( Component[] newComponents... )
    {
        this();

        foreach( comp; newComponents )
            addComponent( comp );
    }

    /**
     * Called once per frame to update all children and components.
     */
    final void update()
    {
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
        foreach( component; componentList )
            component.draw();

        foreach( obj; children )
            obj.draw();
    }

    /**
     * Called when the game is shutting down, to shutdown all children.
     */
    final void shutdown()
    {
        foreach( component; componentList )
            component.shutdown();

        foreach( obj; children )
            obj.shutdown();
    }

    /**
     * Refreshes the object with the given YAML node.
     *
     * Params:
     *  desc =          The node to refresh the object with.
     */
    final void refresh( Description node )
    {
        if( name != node.name )
            changeName( node.name );

        transform.refresh( node.transform );

        // Refresh components
        bool[string] componentExists = zip( StoppingPolicy.shortest, componentList.byKey.map!( k => k.name ), false.repeat ).assocArray();
        foreach( compDesc; node.components )
        {
            // Found it!
            componentExists[ compDesc.componentType.name ] = true;

            // Refresh, or add if it's new
            if( auto comp = compDesc.componentType in componentList )
                comp.refresh( compDesc );
            else
                addComponent( compDesc.createInstance() );
        }

        // Remove old components
        foreach( key; componentExists.keys.filter!( k => !componentExists[k] ) )
            componentList.remove( cast(ClassInfo)ClassInfo.find( key ) );

        // Refresh children
        bool[string] childrenExist = zip( StoppingPolicy.shortest, _children.map!( child => child.name ), false.repeat ).assocArray();
        foreach( childDesc; node.children )
        {
            // Found it!
            childrenExist[ childDesc.name ] = true;

            // Refresh, or add if it's new
            if( auto child = _children.filter!( child => child.name == childDesc.name ).front )
                child.refresh( childDesc );
            else
                addChild( GameObject.create( childDesc ) );
        }

        foreach( key; childrenExist.keys.filter!( k => !childrenExist[k] ) )
            childrenExist.remove( key );
    }

    /**
     * Refresh the component of the given type.
     *
     * Params:
     *  componentType = The type of teh component to refresh.
     *  desc =          The new description of the component.
     */
    final void refreshComponent( ClassInfo componentType, Component.Description desc )
    {
        if( auto comp = componentType in componentList )
        {
            comp.refresh( desc );
        }
    }

    /**
     * Refresh the component of the given type.
     *
     * Params:
     *  ComponentType = The type of teh component to refresh.
     *  desc =          The new description of the component.
     */
    final void refreshComponent( ComponentType )( Component.Description desc )
    {
        refreshComponent( typeid(ComponentType), desc );
    }

    /**
     * Refresh the component of the given type.
     *
     * Params:
     *  componentName = The type of teh component to refresh.
     *  desc =          The new description of the component.
     */
    final void refreshComponent( string componentName, Component.Description desc )
    {
        refreshComponent( getDescription( componentName ).componentType, desc );
    }

    /**
     * Adds a component to the object.
     */
    final void addComponent( Component newComponent )
    in
    {
        assert( newComponent, "Null component added." );
    }
    body
    {
        componentList[ typeid(newComponent) ] = newComponent;
        newComponent.owner = this;
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

        Scene currentScene = findScene();

        if( currentScene )
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
                currentScene.objectById[ child.id ] = child;
                currentScene.idByName[ child.name ] = child.id;
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

        Scene currentScene = findScene();

        // Remove from scene.
        if( currentScene )
        {
            currentScene.objectById.remove( oldChild.id );
            currentScene.idByName.remove( oldChild.name );
        }
    }
}

/**
 * Handles 3D Transformations for an object.
 * Stores position, rotation, and scale
 * and can generate a World matrix, worldPosition/Rotation (based on parents' transforms)
 * as well as forward, up, and right axes based on rotation
 */
struct Transform
{
private:
    vec3f _prevPos;
    quatf _prevRot;
    vec3f _prevScale;
    mat4f _matrix;

    void opAssign( Description desc )
    {
        position = vec3f( desc.position[] );
        rotation = fromEulerAngles( desc.rotation[ 0 ], desc.rotation[ 1 ], desc.rotation[ 2 ] );
        scale = vec3f( desc.scale[] );
    }

    /**
     * Default constructor, most often created by GameObjects.
     *
     * Params:
     *  obj =            The object the transform belongs to.
     */
    this( GameObject obj )
    {
        owner = obj;
        position = vec3f(0,0,0);
        scale = vec3f(1,1,1);
        rotation = quatf.identity;
    }

public:
    /**
     * The struct that will be directly deserialized from the ddl.
     */
    static struct Description
    {
        /// The position of the object.
        @rename( "Position" ) @optional
        float[3] position = [ 0.0f, 0.0f, 0.0f ];

        /// The position of the object.
        @rename( "Rotation" ) @optional
        float[3] rotation = [ 0.0f, 0.0f, 0.0f ];

        /// The position of the object.
        @rename( "Scale" ) @optional
        float[3] scale = [ 1.0f, 1.0f, 1.0f ];
    }

    void refresh( Description desc )
    {
        // TODO: Track if the transform actually changed.
        this = desc;
    }

    /**
     * Create a description from a Transform.
     *
     * Returns:
     *  A new description with components.
     */
    Description toDescription()
    {
        Description desc;
        desc.position = position.vector[ 0..3 ];
        desc.rotation = rotation.toEulerAngles().vector[ 0..3 ];
        desc.scale = scale.vector[ 0..3 ];
        return desc;
    }

    // these should remain public fields, properties return copies not references
    /// The position of the object in local space.
    vec3f position;
    /// The rotation of the object in local space.
    quatf rotation;
    /// The absolute scale of the object. Ignores parent scale.
    vec3f scale;

    /// The object which this belongs to.
    GameObject owner;
    /// The world matrix of the transform.
    mixin( Getter!_matrix );
    //mixin( ThisDirtyGetter!( _matrix, updateMatrix ) );

    @disable this();

    /**
     * This returns the object's position relative to the world origin, not the parent.
     *
     * Returns: The object's position relative to the world origin, not the parent.
     */
    final @property vec3f worldPosition() @safe pure nothrow
    {
        if( owner.parent is null )
            return position;
        else
            return (owner.parent.transform.matrix * vec4f(position, 1.0f)).xyz;
    }

    /**
     * This returns the object's rotation relative to the world origin, not the parent.
     *
     * Returns: The object's rotation relative to the world origin, not the parent.
     */
    final @property quatf worldRotation() @safe pure nothrow
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
    final @property const vec3f forward()
    {
        return vec3f( -2 * (rotation.x * rotation.z + rotation.w * rotation.y),
                            -2 * (rotation.y * rotation.z - rotation.w * rotation.x),
                            -1 + 2 * (rotation.x * rotation.x + rotation.y * rotation.y ));
    }
    ///
    unittest
    {
        import std.stdio;
        writeln( "Dash Transform forward unittest" );

        auto trans = new Transform( null );
        auto forward = vec3f( 0.0f, 1.0f, 0.0f );
        trans.rotation.rotatex( 90.radians );
        assert( almost_equal( trans.forward, forward ) );
    }

    /*
     * Gets the up axis of the current transform.
     *
     * Returns: The up axis of the current transform.
     */
    final @property const vec3f up()
    {
        return vec3f( 2 * (rotation.x * rotation.y - rotation.w * rotation.z),
                        1 - 2 * (rotation.x * rotation.x + rotation.z * rotation.z),
                        2 * (rotation.y * rotation.z + rotation.w * rotation.x));
    }
    ///
    unittest
    {
        import std.stdio;
        writeln( "Dash Transform up unittest" );

        auto trans = new Transform( null );
        auto up = vec3f( 0.0f, 0.0f, 1.0f );
        trans.rotation.rotatex( 90.radians );
        assert( almost_equal( trans.up, up ) );
    }

    /*
     * Gets the right axis of the current transform.
     *
     * Returns: The right axis of the current transform.
     */
    final @property const vec3f right()
    {
        return vec3f( 1 - 2 * (rotation.y * rotation.y + rotation.z * rotation.z),
                        2 * (rotation.x * rotation.y + rotation.w * rotation.z),
                        2 * (rotation.x * rotation.z - rotation.w * rotation.y));
    }
    ///
    unittest
    {
        import std.stdio;
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

        _matrix = mat4f.identity;
        // Scale
        _matrix[ 0 ][ 0 ] = scale.x;
        _matrix[ 1 ][ 1 ] = scale.y;
        _matrix[ 2 ][ 2 ] = scale.z;

        // Rotate
        _matrix = _matrix * rotation.toMatrix!4;

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
