/**
 * Defines the GameObject class, to be subclassed by scripts and instantiated for static objects.
 */
module core.gameobject;
import core.prefabs, core.properties;
import components;
import graphics.graphics, graphics.shaders;
import utility.config;

import yaml;
import gl3n.linalg;

import std.signals, std.conv, std.variant;

class GameObject
{
public:
	/**
	 * The current transform of the object.
	 */
	mixin Property!( "Transform", "transform", "public" );
	/**
	 * The Material belonging to the object
	 */
	mixin Property!( "Material", "material", "public" );
	/**
	 * The Mesh belonging to the object
	 */
	mixin Property!( "Mesh", "mesh", "public" );
	/**
	* The light attached to this object
	*/
	mixin Property!( "Light", "light", "public" );
	/**
	* The camera attached to this object
	*/
	mixin Property!( "Camera", "camera", "public" );
	/**
	 * The object that this object belongs to
	 */
	mixin Property!( "GameObject", "parent" );
	/**
	 * All of the objects which list this as parent
	 */
	mixin Property!( "GameObject[]", "children" );

	mixin Signal!( string, string );

	/**
	 * Create a GameObject from a Yaml node.
	 */
	static GameObject createFromYaml( Node yamlObj )
	{
		GameObject obj;
		Variant prop;
		Node innerNode;

		// Try to get from script
		if( Config.tryGet!string( "Script.ClassName", prop, yamlObj ) )
		{
			const ClassInfo scriptClass = ClassInfo.find( prop.get!string );

			if( Config.tryGet!string( "InstanceOf", prop, yamlObj ) )
			{
				obj = Prefabs[ prop.get!string ].createInstance( scriptClass );
			}
			else
			{
				obj = cast(GameObject)scriptClass.create();
			}
		}

		if( Config.tryGet!string( "InstanceOf", prop, yamlObj ) )
		{
			obj = Prefabs[ prop.get!string ].createInstance();
		}
		else
		{
			obj = new GameObject;
		}

		if( Config.tryGet!string( "Camera", prop, yamlObj ) )
		{
			obj.addComponent( new Camera( obj ) );
		}

		if( Config.tryGet!string( "Material", prop, yamlObj ) )
		{
			obj.addComponent( Assets.get!Material( prop.get!string ) );
		}

		if( Config.tryGet!string( "Mesh", prop, yamlObj ) )
		{
			obj.addComponent( Assets.get!Mesh( prop.get!string ) );
		}

		if( Config.tryGet( "Transform", innerNode, yamlObj ) )
		{
			vec3 transVec;
			if( Config.tryGet( "Scale", transVec, innerNode ) )
				obj.transform.scale = transVec;
			if( Config.tryGet( "Position", transVec, innerNode ) )
				obj.transform.position = transVec;
			if( Config.tryGet( "Rotation", transVec, innerNode ) )
				obj.transform.rotation = quat.euler_rotation( transVec.y, transVec.z, transVec.x );
		}

		if( Config.tryGet!Light( "Light", prop, yamlObj ) )
		{
			obj.addComponent( prop.get!Light );
		}

		return obj;
	}

	/**
	 * Creates basic GameObject with transform and connection to transform's emitter.
	 */
	this()
	{
		transform = new Transform( this );
		transform.connect( &emit );
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
	final void addComponent( T )( T newComponent ) if( is( T : Component ) )
	{
		componentList[ T.classinfo ] = newComponent;

		// Add component to proper property
		if( typeid( newComponent ) == typeid( Material ) )
			material = cast(Material)newComponent;
		else if( typeid( newComponent ) == typeid( Mesh ) )
			mesh = cast(Mesh)newComponent;
		else if( typeid( newComponent ) == typeid( DirectionalLight ) || 
				 typeid( newComponent ) == typeid( AmbientLight ) )
			light = cast(Light)newComponent;
		else if( typeid( newComponent ) == typeid( Camera ) )
			camera = cast(Camera)newComponent;
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

private:
	Component[ClassInfo] componentList;
}

class Transform
{
public:
	this( GameObject obj = null )
	{
		owner = obj;
		position = vec3(0,0,0);
		scale = vec3(1,1,1);
		rotation = quat(0,0,0,0);
		updateMatrix();
	}

	~this()
	{
		//destroy( position );
		//destroy( rotation ); 
		//destroy( scale );
	}

	mixin Property!( "GameObject", "owner" );
	vec3 position;
	quat rotation;
	vec3 scale;
	//mixin EmmittingProperty!( "vec3", "position", "public" );
	//mixin EmmittingProperty!( "quat", "rotation", "public" );
	//mixin EmmittingProperty!( "vec3", "scale", "public" );

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

	final void updateMatrix()
	{
		_matrix = mat4.identity;
		// Scale
		_matrix.scale([scale.x, scale.y, scale.z]);
		//Rotate
		_matrix.rotation( rotation.to_matrix!( 3, 3 ) );
		// Translate
		_matrix.translation([position.x, position.y, position.z]);

		_matrixIsDirty = false;
	}

private:
	mat4 _matrix;
	bool _matrixIsDirty;

	final void setMatrixDirty( string prop, string newVal )
	{
		_matrixIsDirty = true;
	}
}