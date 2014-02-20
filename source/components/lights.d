module components.lights;
import core.properties, core.gameobject;
import components.component;
import graphics.shaders;
import math.vector;

class Light : Component
{
public:
	mixin Property!( "Vector!3", "color", "public" );

	this( GameObject owner, Vector!3 color )
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
	this( Vector!3 color )
	{
		super( color );
	}
}

/* 
 * Directional Light data
 */
class DirectionalLight : Light
{
public:
	mixin Property!( "Vector!3", "direction" );

	this( GameObject owner, Vector!3 color, Vector!3 direction )
	{
		this.direction = direction;
		super( owner, color );
	}
}

/*
 * Point Light Stub
 */
class PointLight : Light
{
public:
	this( GameObject owner, Vector!3 color )
	{
		super( owner, color );
	}
}

/*
 * SpotLight Stub
 */
class SpotLight : Light
{
public:
	this( GameObject owner, Vector!3 color )
	{
		super( owner, color );
	}
}
