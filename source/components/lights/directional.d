module components.lights.directional;
import core.properties;
import components.lights.light;
import math.vector;

class DirectionalLight : Light
{
public:
	mixin Property!( "Vector!3", "direction" );

	this( Vector!3 color, Vector!3 direction )
	{
		this.direction = direction;
		super( color );
	}
}
