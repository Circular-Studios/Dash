/**
 * TODO
 */
module components.lights;
import core, components, graphics;
import utility;

import gl3n.linalg;

/**
 * TODO
 */
shared class Light : IComponent
{
private:
    vec3 _color;

public:
    /// TODO
    mixin( Property!( _color, AccessModifier.Public ) );

    this( shared vec3 color )
    {
        this.color = color;
    }
    
    override void update() { }
    override void shutdown() { }
}

/**
 * TODO
 */
shared class AmbientLight : Light 
{ 
    this( shared vec3 color )
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
    uint _shadowMapFrameBuffer;
    uint _shadowMapTexture;


public:
    /// The direction the light points in.
    mixin( Property!( _direction, AccessModifier.Public ) );
    /// The FrameBuffer for the shadowmap.
    mixin( Property!( _shadowMapFrameBuffer ) );
    /// The shadow map's depth texture.
    mixin( Property!( _shadowMapTexture ) );

    this( shared vec3 color, shared vec3 direction )
    {
        this.direction = direction;
        super( color );

        // generate framebuffer/texture for shadow map

    }
}

/*
 * Point Light data
 */
shared class PointLight : Light
{
private:
    float _radius;
    float _falloffRate;
    mat4 _matrix;

public:
    /// The area that lighting will be calculated for.
    mixin( Property!( _radius, AccessModifier.Public ) );
    /// The light's exponential attenuation modifier.
    mixin( Property!( _falloffRate, AccessModifier.Public ) );

    this( shared vec3 color, float radius, float falloffRate )
    {
        this.radius = radius;
        this.falloffRate = falloffRate;
        super( color );
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
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
    this( shared vec3 color )
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
