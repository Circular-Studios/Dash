module components.lights;
import core, components, graphics;

import gl3n.linalg;

class Light : IComponent
{
private:
	vec3 _color;

public:
	mixin( Property!( _color, AccessModifier.Public ) );

	this( vec3 color )
	{
		this.color = color;
	}
	
	override void update() { }

	override void shutdown() { }
}

class AmbientLight : Light 
{ 
	this( vec3 color )
	{
		super( color );
	}
}

/* 
 * Directional Light data
 */
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

/*
 * Point Light data
 */
class PointLight : Light
{
private:
	float _radius;
public:
	/*
	 * The area that lighting will be calculated for 
	 */
	mixin( Property!(_radius, AccessModifier.Public) );

	this( vec3 color, float radius )
	{
		this.radius = radius;
		super( color );
	}
}

/*
 * SpotLight Stub
 */
class SpotLight : Light
{
public:
	this( vec3 color )
	{
		super( color );
	}
}
