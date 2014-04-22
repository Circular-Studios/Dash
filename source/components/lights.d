/**
 * Contains the base class for all light types, Light, as well as
 * AmbientLight, DirectionalLight, PointLight, SpotLight.
 */
module components.lights;
import core, components, graphics;
import utility;

import gl3n.linalg;
import derelict.opengl3.gl3;

/**
 * Base class for lights.
 */
shared class Light : IComponent
{
private:
    vec3 _color;

public:
    /// The color the light gives off.
    mixin( Property!( _color, AccessModifier.Public ) );

    this( shared vec3 color )
    {
        this.color = color;
    }
    
    override void update() { }
    override void shutdown() { }
}

/**
 * Ambient Light
 */
shared class AmbientLight : Light 
{ 
    this( shared vec3 color )
    {
        super( color );
    }
}

/* 
 * Directional Light
 */
shared class DirectionalLight : Light
{
private:
    vec3 _direction;
    uint _shadowMapFrameBuffer;
    uint _shadowMapTexture;
    mat4 _view;
    mat4 _proj;

public:
    /// The direction the light points in.
    mixin( Property!( _direction, AccessModifier.Public ) );
    /// The FrameBuffer for the shadowmap.
    mixin( Property!( _shadowMapFrameBuffer ) );
    /// The shadow map's depth texture.
    mixin( Property!( _shadowMapTexture ) );
    mixin( Property!( _view, AccessModifier.Public ) );
    mixin( Property!( _proj, AccessModifier.Public ) );

    this( shared vec3 color, shared vec3 direction )
    {
        this.direction = direction;
        super( color );

        // generate framebuffer for shadow map
        shadowMapFrameBuffer = 0;
        glGenFramebuffers( 1, cast(uint*)&_shadowMapFrameBuffer );
        glBindFramebuffer( GL_FRAMEBUFFER, _shadowMapFrameBuffer );

        // generate depth texture of shadow map
        glGenTextures( 1, cast(uint*)&_shadowMapTexture );
        glBindTexture( GL_TEXTURE_2D, _shadowMapTexture );
        glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT16, 1024, 1024, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

        glFramebufferTexture2D( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, _shadowMapTexture, 0 );

        // don't want any info besides depth
        glDrawBuffer( GL_NONE );

        // check for success
        if( glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE )
        {
            logFatal("Shadow map frame buffer failure.");
            assert(false);
        }
    }
}

/*
 * Point Light
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
