module core.gameobject;
import core.properties;
import components.icomponent;
import graphics.shaders.ishader;
import scripting.scripts;
import utility.config;
import math.transform;

import yaml;

import std.signals, std.conv;

final class GameObject
{
public:
	mixin( Property!( "IShader", "shader", "public" ) );
	mixin( Property!( "Transform", "transform", "public" ) );
	mixin Signal!( string, string );

	static GameObject createFromYaml( Node yamlObject )
	{
		GameObject obj;

		// Try to get from script
		string className = Config.get!string( yamlObject, "Script.ClassName" );
		if( className is null )
			obj = new GameObject;
		else
			obj = Scripts.callCtor!GameObject( className );

		return obj;
	}

	this()
	{
		transform = new Transform;
		transform.connect( &emit );
	}

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

	final void update()
	{
		foreach( ci, component; componentList )
			component.update();

		onUpdate();
	}

	final void draw()
	{
		foreach( ci, component; componentList )
			component.draw( shader );

		onDraw();
	}

	final void shutdown()
	{
		onShutdown();

		foreach( ci, component; componentList )
			component.shutdown();
		foreach( key; componentList.keys )
			componentList.remove( key );
	}

	final void addComponent( T )( T newComponent )
	{
		componentList[ T.classinfo ] = newComponent;
	}

	final T getComponent( T )()
	{
		return componentList[ T.classinfo ];
	}

	// Overridables
	void onUpdate() { }
	void onDraw() { }
	void onShutdown() { }
	void onCollision( GameObject other ) { }

private:
	IComponent[ClassInfo] componentList;
}
