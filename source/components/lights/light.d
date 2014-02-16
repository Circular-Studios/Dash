module components.lights.light;
import core.properties;
import components.component;
import graphics.shaders.shader;
import math.vector;

class Light : Component
{
public:
	mixin Property!( "Vector!3", "color", "public" );

	this( Vector!3 color )
	{
		super( null );

		this.color = color;
	}
	
	override void update()
	{

	}
	
	override void draw( Shader shader )
	{

	}

	override void shutdown()
	{

	}

}