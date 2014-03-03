module components.lights;
import core, components, graphics;

import gl3n.linalg;

class Light : Component
{
private:
	vec3 _color;

public:
	mixin( Property!( _color, AccessModifier.Public ) );

	this( GameObject owner, vec3 color )
	{
		super( owner );

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
	this( GameObject owner, vec3 color )
	{
		super( owner, color );
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

	this( GameObject owner, vec3 color, vec3 direction )
	{
		this.direction = direction;
		super( owner, color );
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

	this( GameObject owner, vec3 color, float radius )
	{
		this.radius = radius;
		super( owner, color );
	}
}

/*
 * SpotLight Stub
 */
class SpotLight : Light
{
public:
	this( GameObject owner, vec3 color )
	{
		super( owner, color );
	}
}
