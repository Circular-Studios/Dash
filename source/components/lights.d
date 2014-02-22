module components.lights;
import core.properties;
import components.component;
import graphics.shaders;

import gl3n.linalg;

class Light : Component
{
public:
	mixin Property!( "vec3", "color", "public" );

	this( vec3 color )
	{
		super( null );

		this.color = color;
	}
	
	override void update()
	{

	}

	override void shutdown()
	{

	}

}

class AmbientLight : Light 
{ 
	this( vec3 color )
	{
		super( color );
	}
}

class DirectionalLight : Light
{
public:
	mixin Property!( "vec3", "direction" );

	this( vec3 color, vec3 direction )
	{
		this.direction = direction;
		super( color );
	}
}
