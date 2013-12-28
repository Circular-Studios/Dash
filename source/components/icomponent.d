module components.icomponent;
import core.properties, core.gameobject;
import graphics.shaders.ishader;

/**
 * Interface for components to implement.
 */
abstract class IComponent
{
	this( GameObject owner )
	{
		this.owner = owner;
	}

	/**
	 * Function called on update.
	 */
	abstract void update();
	/**
	 * Function calledn on draw.
	 */
	abstract void draw( IShader shader );
	/**
	 * Function called on shutdown.
	 */
	abstract void shutdown();

	/**
	 * The GameObject that owns this component.
	 */
	mixin( Property!( "GameObject", "owner", "protected" ) );
}
