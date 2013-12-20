module components.icomponent;
import core.properties, core.gameobject;
import graphics.shaders.ishader;

abstract class IComponent
{
	this( GameObject owner )
	{
		this.owner = owner;
	}

	abstract void update();
	abstract void draw( IShader shader );
	abstract void shutdown();

	mixin( Property!( "GameObject", "owner" ) );
}
