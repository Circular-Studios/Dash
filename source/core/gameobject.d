/**
 * Defines the GameObject class, to be subclassed by scripts and instantiated for static objects.
 */
module core.gameobject;
import core.properties;
import components.icomponent;
import graphics.shaders.ishader;
import math.transform;

import yaml;
import std.signals, std.conv;

final class GameObject
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
	static GameObject createFromYaml( Node yamlObject )
	{
		GameObject obj;

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

	/// Called on the update cycle.
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
