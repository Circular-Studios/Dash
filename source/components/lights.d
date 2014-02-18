module components.lights;
import core.properties;
import components.component;
import graphics.shaders;
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
