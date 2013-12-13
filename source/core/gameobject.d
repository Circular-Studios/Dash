module core.gameobject;
import core.global;
import components.icomponent;
import graphics.shaders.ishader;

class GameObject
{
public:
	mixin( Property!( "IShader", "shader", "public" ) );
	//mixin( Property!( "Transform", "transform", "public" ) );

	this( IShader shader = null )
	{
		// Transform
		this.shader = shader;
	}

	/*this( Yaml jsonObject )
	{
		// Handle stuff
	}*/

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
			component.draw();
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

private:
	IComponent[ClassInfo] componentList;
}
