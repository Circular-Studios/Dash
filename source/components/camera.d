module components.camera;
import core.gameobject;
import components.icomponent;
import math.matrix;

class Camera : IComponent
{
	this( GameObject owner )
	{
		super( owner );
	}

	@property Matrix!4 viewMatrix()
	{
		return new Matrix!4;
	}
}
