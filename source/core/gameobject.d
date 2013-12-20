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
	mixin( Property!( "IShader", "shader", "public" ) );
	mixin( Property!( "Transform", "transform", "public" ) );

	this()
	{
		transform = new Transform;
		transform.connect( &emit );
	}

	this( IShader shader )
	{
		this();

		// Transform
		this.shader = shader;
	}

	this( Node jsonObject )
	{
		this();
		// Handle stuff
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

	void update()
	{
		foreach( ci, component; componentList )
		{
			component.update();
		}
	}

	void draw()
	{
		foreach( ci, component; componentList )
		{
			component.draw( shader );
		}
	}

	void shutdown()
	{
		foreach( ci, component; componentList )
		{
			component.shutdown();
		}

		foreach( key; componentList.keys )
		{
			componentList.remove( key );
		}
	}

	void onCollision( GameObject other )
	{
		
	}

	void addComponent( T )( T newComponent )
	{
		componentList[ T.classinfo ] = newComponent;
	}

	T getComponent( T )()
	{
		return componentList[ T.classinfo ];
	}

	mixin Signal!( string, string );

private:
	IComponent[ClassInfo] componentList;
}
