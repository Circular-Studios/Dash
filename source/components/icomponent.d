/**
 * Defines the Component abstract class, which is the base for all components.
 */
module components.icomponent;
import core, graphics;

import yaml;

/**
 * Interface for components to implement.
 */
shared interface IComponent
{
public:
	static void function( Node, shared GameObject )[string] initializers;

	/**
	 * The GameObject that owns this component.
	 */
	final @property ref shared(GameObject) owner()
	{
		static shared(GameObject) owner;
		
		return owner;
	}

	/**
	 * Function called on update.
	 */
	void update();
	/**
	 * Function called on shutdown.
	 */
	void shutdown();
}
