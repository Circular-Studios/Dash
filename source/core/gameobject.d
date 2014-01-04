/**
 * Defines the GameObject class, to be subclassed by scripts and instantiated for static objects.
 */
module core.gameobject;
import core.properties, core.main;
import components.icomponent, components.assets, components.texture, components.mesh;
import graphics.shaders.ishader;
import utility.config;
import math.transform, math.vector;

import yaml;

import std.signals, std.conv, std.variant;

class GameObject
{
public:
	/**
	 * The shader this object uses to draw.
	 */
	mixin Property!( "IShader", "shader", "public" );
	/**
	 * The current transform of the object.
	 */
	mixin Property!( "Transform", "transform", "public" );
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
			obj = cast(GameObject)Object.factory( prop.get!string );
		else
			obj = new GameObject;

		if( Config.tryGet!string( "Camera", prop, yamlObj ) )
		{
			//TODO: Setup camera
		}

		if( Config.tryGet!string( "Texture", prop, yamlObj ) )
			obj.addComponent( Assets.getAsset!Texture( prop.get!string ) );

		if( Config.tryGet!string( "AwesomiumView", prop, yamlObj ) )
		{
			//TODO: Initialize Awesomium view
		}

		if( Config.tryGet!string( "Mesh", prop, yamlObj ) )
			obj.addComponent( Assets.getAsset!Mesh( prop.get!string ) );

		if( Config.tryGet( "Transform", innerNode, yamlObj ) )
		{
			Vector!3 transVec;
			if( Config.tryGet( "Scale", transVec, innerNode ) )
				obj.transform.scale = transVec;
			if( Config.tryGet( "Position", transVec, innerNode ) )
				obj.transform.position = transVec;
			//TODO: Quaternion from Euler angles
			//if( Config.tryGet( "Rotation", transVec, innerNode ) )
			//	obj.transform.rotation = transVec;
		}

		return obj;
	}

	/**
	 * Creates basic GameObject with transform and connection to transform's emitter.
	 */
	this()
	{
		transform = new Transform;
		transform.connect( &emit );
	}

	/**
	 * Initializes GameObject with shader
	 */
	this( IShader shader )
	{
		this();
		this.shader = shader;
	}

	~this()
	{
		destroy( transform );

		if( shader )
		{
			destroy( shader );
			shader = null;
		}
	}

	/**
	 * Called once per frame to update all components.
	 */
	final void update()
	{
		foreach( ci, component; componentList )
			component.update();

		onUpdate();
	}

	/**
	 * Called once per frame to draw all components.
	 */
	final void draw()
	{
		foreach( ci, component; componentList )
			component.draw( shader );

		onDraw();
	}

	/**
	 * Called when the game is shutting down, to shutdown all components.
	 */
	final void shutdown()
	{
		onShutdown();

		foreach( ci, component; componentList )
			component.shutdown();
		foreach( key; componentList.keys )
			componentList.remove( key );
	}

	/**
	 * Adds a component to the object.
	 */
	final void addComponent( T )( T newComponent )
	{
		componentList[ T.classinfo ] = newComponent;
	}

	/**
	 * Gets a component of the given type.
	 */
	final T getComponent( T )()
	{
		return componentList[ T.classinfo ];
	}

	// Overridables
	void onUpdate() { }
	/// Called on the draw cycle.
	void onDraw() { }
	/// Called on shutdown.
	void onShutdown() { }
	/// Called when the object collides with another object.
	void onCollision( GameObject other ) { }

private:
	IComponent[ClassInfo] componentList;
}
