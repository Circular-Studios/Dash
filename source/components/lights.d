module components.lights;
import core, components, graphics;

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

static this()
{
	import yaml;
	IComponent.initializers[ "Light" ] = ( Node yml, shared GameObject obj )
	{
		obj.addComponent( cast(shared)yml.get!Light );
	};
}
