/**
 * Defines the GameObject class, to be subclassed by scripts and instantiated for static objects.
 */
module core.gameobject;
import core, components, graphics, utility;

import yaml;
import gl3n.linalg, gl3n.math;

import std.signals, std.conv, std.variant;

/**
 * Manages all components and transform in the world. Can be overridden.
 */
class GameObject
{
private:
	Transform _transform;
	Material _material;
	Mesh _mesh;
	Light _light;
	Camera _camera;
	GameObject _parent;
	GameObject[] _children;
	IComponent[TypeInfo] componentList;

public:
	/// The current transform of the object.
	mixin( Property!( _transform, AccessModifier.Public ) );
	/// The Material belonging to the object.
	mixin( Property!( _material, AccessModifier.Public ) );
	/// The Mesh belonging to the object.
	mixin( Property!( _mesh, AccessModifier.Public ) );
	/// The light attached to this object.
	mixin( Property!( _light, AccessModifier.Public ) );
	/// The camera attached to this object.
	mixin( Property!( _camera, AccessModifier.Public ) );
	/// The object that this object belongs to.
	mixin( Property!( _parent, AccessModifier.Public ) );
	/// All of the objects which list this as parent
	mixin( Property!( _children, AccessModifier.Public ) );

	string name;

	/**
	 * Create a GameObject from a Yaml node.
	 * 
	 * Params:
	 * 	yamlObj =			The YAML node to pull info from.
	 * 	scriptOverride =	The ClassInfo to use to create the object. Overrides YAML setting.
	 * 
	 * Returns:
	 * 	A new game object with components and info pulled from yaml.
	 */
	static GameObject createFromYaml( Node yamlObj, const ClassInfo scriptOverride = null )
	{
		GameObject obj;
		string prop;
		Node innerNode;

		string objName = yamlObj[ "Name" ].as!string;
		
		// Try to get from script
		if( scriptOverride !is null )
		{
			obj = cast(GameObject)scriptOverride.create();
		}
		else
		{
			// Get class to create script from
			const ClassInfo scriptClass = Config.tryGet( "Script.ClassName", prop, yamlObj )
					? ClassInfo.find( prop )
					: null;

			// Check that if a Script.ClassName was provided that it was valid
			if( Config.tryGet("Script.ClassName", prop, yamlObj ) && scriptClass is null )
			{
				logWarning( objName, ": Unable to find Script ClassName: ", prop );
			}
			
			if( Config.tryGet( "InstanceOf", prop, yamlObj ) )
			{
				obj = Prefabs[ prop ].createInstance( scriptClass );
			}
			else
			{
				obj = scriptClass
						? cast(GameObject)scriptClass.create()
						: new GameObject;
			}
		}

		// set object name
		obj.name = objName;

		// Init transform
		if( Config.tryGet( "Transform", innerNode, yamlObj ) )
		{
			vec3 transVec;
			if( Config.tryGet( "Scale", transVec, innerNode ) )
				obj.transform.scale = transVec;
			if( Config.tryGet( "Position", transVec, innerNode ) )
				obj.transform.position = transVec;
			if( Config.tryGet( "Rotation", transVec, innerNode ) )
				obj.transform.rotation = quat.euler_rotation( radians(transVec.y), radians(transVec.z), radians(transVec.x) );
		}
		
		// Init components
		foreach( string key, Node value; yamlObj )
		{
			if( key == "Name" || key == "Script" || key == "Parent" || key == "InstanceOf" || key == "Transform" )
				continue;

			if( auto init = key in IComponent.initializers )
				obj.addComponent( (*init)( value, obj ) );
			else
				logWarning( "Unknown key: ", key );
		}

		obj.transform.updateMatrix();
		return obj;
	}

	mixin Signal!( string, string );

	/**
	 * Creates basic GameObject with transform and connection to transform's emitter.
	 */
	this()
	{
		transform = new Transform( this );
		transform.connect( &emit );
		material = new Material();
	}

	~this()
	{
		destroy( transform );
	}

	/**
	 * Called once per frame to update all components.
	 */
	final void update()
	{
		onUpdate();

		foreach( ci, component; componentList )
			component.update();
	}

	/**
	 * Called once per frame to draw all components.
	 */
	final void draw()
	{
		onDraw();

		if( mesh !is null )
		{
			Graphics.drawObject( this );
		}
		if( light !is null )
		{
			Graphics.addLight( light );
		}
	}

	/**
	 * Called when the game is shutting down, to shutdown all components.
	 */
	final void shutdown()
	{
		onShutdown();

		/*foreach_reverse( ci, component; componentList )
		{
			component.shutdown();
			componentList.remove( ci );
		}*/
	}

	/**
	 * Adds a component to the object.
	 */
	final void addComponent( T )( T newComponent ) if( is( T : IComponent ) )
	{
		componentList[ typeid(T) ] = newComponent;
	}

	/**
	 * Gets a component of the given type.
	 */
	final T getComponent( T )() if( is( T : Component ) )
	{
		return componentList[ T.classinfo ];
	}

	final void addChild( GameObject object )
	{
		object._children ~= object;
		object.parent = this;
	}

	/// Called on the update cycle.
	void onUpdate() { }
	/// Called on the draw cycle.
	void onDraw() { }
	/// Called on shutdown.
	void onShutdown() { }
	/// Called when the object collides with another object.
	void onCollision( GameObject other ) { }
}

class Transform
{
private:
	GameObject _owner;

public:
	mixin Properties;

	// these should remain public fields, properties return copies not references
	vec3 position;
	quat rotation;
	vec3 scale;

	mixin( Property!( _owner, AccessModifier.Public ) );


	this( GameObject obj = null )
	{
		owner = obj;
		position = vec3(0,0,0);
		scale = vec3(1,1,1);
		rotation = quat.identity;
		updateMatrix();
	}

	~this()
	{
		//destroy( position );
		//destroy( rotation ); 
		//destroy( scale );
	}

	/**
	* This returns the object's position relative to the world origin, not the parent
	*/
	final @property vec3 worldPosition()
	{
		if( owner.parent is null )
			return position;
		else
			return owner.parent.transform.worldPosition + position;
	}

	/**
	* This returns the object's rotation relative to the world origin, not the parent
	*/
	final @property quat worldRotation()
	{
		if( owner.parent is null )
			return rotation;
		else
			return owner.parent.transform.worldRotation * rotation;
	}

	final @property mat4 matrix()
	{
		if( _matrixIsDirty )
			updateMatrix();

		if( owner.parent is null )
			return _matrix;
		else
			return owner.parent.transform.matrix * _matrix;
	}

	mixin Signal!( string, string );

	/**
	 * Rebuilds the object's matrix
	 */
	final void updateMatrix()
	{
		_matrix = mat4.identity;
		// Scale
		_matrix.scale( scale.x, scale.y, scale.z );
		// Rotate
		_matrix = _matrix * rotation.to_matrix!( 4, 4 );
		// Translate
		_matrix.translate( position.x, position.y, position.z );

		_matrixIsDirty = false;
	}

private:
	mat4 _matrix;
	// Update flag
	bool _matrixIsDirty;

	final void setMatrixDirty( string prop, string newVal )
	{
		_matrixIsDirty = true;
	}
}
