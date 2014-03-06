/**
 * Defines the Component abstract class, which is the base for all components.
 */
module components.icomponent;
import core, graphics;

import yaml;

/**
 * Interface for components to implement.
 */
interface IComponent
{
public:
	/**
	 * Functions to call when creating components.
	 */
	static IComponent function( Node, GameObject )[string] initializers;

	/**
	 * The GameObject that owns this component.
	 */
	final @property GameObject owner()
	{
		GameObject* owner = this in owners;
		if( owner )
			return *owner;
		else
			return null;
	}

	/// ditto
	final @property void owner( GameObject newOwner )
	{
		owners[ this ] = newOwner;
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

private GameObject[ IComponent ] owners;
