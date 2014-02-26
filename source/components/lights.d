module components.lights;
import core, components, graphics;

import gl3n.linalg;

class Light : Component
{
private:
	vec3 _color;

public:
	mixin( Property!( _color, AccessModifier.Public ) );

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
private:
	vec3 _direction;

public:
	mixin( Property!( _direction, AccessModifier.Public ) );

	this( vec3 color, vec3 direction )
	{
		this.direction = direction;
		super( color );
	}
}
