module components.lights;
import core, components, graphics;
import utility;

import gl3n.linalg;

shared class Light : IComponent
{
private:
	vec3 _color;

public:
	mixin( Property!( _color, AccessModifier.Public ) );

	this( vec3 color )
	{
		this.color = cast(shared)vec3( color );
	}
	
	override void update() { }
	override void shutdown() { }
}

shared class AmbientLight : Light 
{ 
	this( vec3 color )
	{
		super( color );
	}
}

/* 
 * Directional Light data
 */
shared class DirectionalLight : Light
{
private:
	vec3 _direction;

public:
	mixin( Property!( _direction, AccessModifier.Public ) );

	this( vec3 color, vec3 direction )
	{
		this.direction = cast(shared)vec3( direction );
		super( color );
	}
}

/*
 * Point Light data
 */
shared class PointLight : Light
{
private:
	float _radius;
	mat4 _matrix;

public:
	/*
	 * The area that lighting will be calculated for 
	 */
	mixin( Property!( _radius, AccessModifier.Public ) );

	this( vec3 color, float radius )
	{
		this.radius = radius;
		super( color );
	}

	public shared(mat4) getTransform()
	{
		_matrix = mat4.identity;
		// Scale
		_matrix[ 0 ][ 0 ] = radius;
		_matrix[ 1 ][ 1 ] = radius;
		_matrix[ 2 ][ 2 ] = radius;
		// Translate
		shared vec3 position = owner.transform.worldPosition;
		_matrix[ 0 ][ 3 ] = position.x;
		_matrix[ 1 ][ 3 ] = position.y;
		_matrix[ 2 ][ 3 ] = position.z;
		return _matrix;
	}

}

/*
 * SpotLight Stub
 */
shared class SpotLight : Light
{
public:
	this( vec3 color )
	{
		super( color );
	}
}

static this()
{
	import yaml;
	IComponent.initializers[ "Light" ] = ( Node yml, shared GameObject obj )
	{
		obj.light = cast(shared)yml.get!Light;
		obj.light.owner = obj;

		return obj.light;
	};
}
