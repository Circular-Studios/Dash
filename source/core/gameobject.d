/**
 * Defines the GameObject class, to be subclassed by scripts and instantiated for static objects.
 */
module core.gameobject;
import core, components, graphics, utility;

import yaml;
import gl3n.linalg, gl3n.math;

import std.conv, std.variant;

enum AnonymousName = "__anonymous";

/**
 * Manages all components and transform in the world. Can be overridden.
 */
shared class GameObject
{
private:
	Transform _transform;
	Material _material;
	Mesh _mesh;
	Light _light;
	Camera _camera;
	GameObject _parent;
	GameObject[] _children;
	string _name;
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
	/// All of the objects which list this as parent.
	mixin( Property!( _children, AccessModifier.Public ) );
	/// The name of the object.
	mixin( Property!_name );

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
	static shared(GameObject) createFromYaml( Node yamlObj, ref string[shared GameObject] parents, ref string[][shared(GameObject)] children, const ClassInfo scriptOverride = null )
	{
		shared GameObject obj;
		string prop;
		Node innerNode;

		// Try to get from script
		if( scriptOverride !is null )
		{
			obj = cast(shared GameObject)scriptOverride.create();
		}
		else
		{
			// Get class to create script from
			const ClassInfo scriptClass = Config.tryGet( "Script.ClassName", prop, yamlObj )
					? ClassInfo.find( prop )
					: null;
			
			if( Config.tryGet( "InstanceOf", prop, yamlObj ) )
			{
				obj = Prefabs[ prop ].createInstance( parents, children, scriptClass );
			}
			else
			{
				obj = scriptClass
						? cast(shared GameObject)scriptClass.create()
						: new shared GameObject;
			}
		}

		// set object name
		obj.name = Config.get!string( "Name", yamlObj );

		// Init transform
		if( Config.tryGet( "Transform", innerNode, yamlObj ) )
		{
			vec3 transVec;
			if( Config.tryGet( "Scale", transVec, innerNode ) )
				obj.transform.scale = cast(shared)vec3( transVec );
			if( Config.tryGet( "Position", transVec, innerNode ) )
				obj.transform.position = cast(shared)vec3( transVec );
			if( Config.tryGet( "Rotation", transVec, innerNode ) )
				obj.transform.rotation = cast(shared)quat.euler_rotation( radians(transVec.y), radians(transVec.z), radians(transVec.x) );
		}

		// If parent is specified, add it to the map
		if( Config.tryGet( "Parent", prop, yamlObj ) )
			parents[ obj ] = prop;

		if( Config.tryGet( "Children", innerNode, yamlObj ) )
		{
			if( innerNode.isSequence )
			{
				foreach( Node child; innerNode )
				{
					if( child.isScalar )
					{
						// Add child name to map.
						children[ obj ] ~= child.get!string;
					}
					else
					{
						// If inline object, create it and add it as a child.
						obj.addChild( GameObject.createFromYaml( child, parents, children ) );
					}
				}
			}
			else
			{
				logWarning( "Scalar values and mappings in 'Children' of ", obj.name, " are not supported, and it is being ignored." );
			}
		}
				
		// Init components
		foreach( string key, Node value; yamlObj )
		{
			if( key == "Name" || key == "Script" || key == "Parent" ||
			    key == "InstanceOf" || key == "Transform" || key == "Children" )
				continue;

			if( auto init = key in IComponent.initializers )
				obj.addComponent( (*init)( value, obj ) );
			else
				logWarning( "Unknown key: ", key );
		}

		obj.transform.updateMatrix();
		return obj;
	}

	/**
	 * Creates basic GameObject with transform and connection to transform's emitter.
	 */
	this()
	{
		transform = new shared Transform( this );
		//transform.connect( &emit );
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
	final void addComponent( T )( shared T newComponent ) if( is( T : IComponent ) )
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

	final void addChild( shared GameObject object )
	{
		_children ~= object;
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

shared class Transform
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


	this( shared GameObject obj = null )
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
			return cast()position;
		else
			return owner.parent.transform.worldPosition + cast()position;
	}

	/**
	* This returns the object's rotation relative to the world origin, not the parent
	*/
	final @property quat worldRotation()
	{
		if( owner.parent is null )
			return cast()rotation;
		else
			return owner.parent.transform.worldRotation * cast()rotation;
	}

	final @property mat4 matrix()
	{
		if( _matrixIsDirty )
			updateMatrix();

		if( owner.parent is null )
			return cast()_matrix;
		else
			return owner.parent.transform.matrix * _matrix;
	}

	/**
	 * Rebuilds the object's matrix
	 */
	final void updateMatrix()
	{
		_matrix = mat4.identity;
		// Scale
		_matrix[ 0 ][ 0 ] = (cast()scale).x;
		_matrix[ 1 ][ 1 ] = (cast()scale).y;
		_matrix[ 2 ][ 2 ] = (cast()scale).z;
		// Rotate
		_matrix = (cast()_matrix) * (cast()rotation).to_matrix!( 4, 4 );

		//logInfo( "Pre translate: ", cast()_matrix );
		// Translate
		_matrix[ 0 ][ 3 ] = (cast()position).x;
		_matrix[ 1 ][ 3 ] = (cast()position).y;
		_matrix[ 2 ][ 3 ] = (cast()position).z;
		//logInfo( "Post: ", cast()_matrix );

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
