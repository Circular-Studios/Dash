/**
 * Contains the base class for all light types, Light, as well as
 * AmbientLight, DirectionalLight, PointLight, SpotLight.
 */
module dash.components.lights;
import dash.core, dash.components, dash.graphics;
import dash.utility;

import derelict.opengl3.gl3;
import std.math;

mixin( registerComponents!() );

/**
 * Base class for lights.
 */
abstract class Light : Component
{
public:
    /// The color the light gives off.
    @rename( "Color" ) @optional
    vec3f color;
    /// If it should cast shadows
    @rename( "CastShadows" ) @optional
    bool castShadows;

    this( vec3f color )
    {
        this.color = color;
        castShadows = false;
    }

    override void update() { }
    override void shutdown() { }
}

/**
 * Ambient Light
 */
class AmbientLight : Light
{
    this( vec3f color = vec3f( 1.0f ) )
    {
        super( color );
    }
}

/**
 * Directional Light
 */
class DirectionalLight : Light
{
private:
    uint _shadowMapFrameBuffer;
    uint _shadowMapTexture;
    mat4f _projView;
    int _shadowMapSize;

public:
    /// The direction the light points in.
    @rename( "Direction" ) @optional
    vec3f direction;
    /// The FrameBuffer for the shadowmap.
    mixin( Property!( _shadowMapFrameBuffer ) );
    /// The shadow map's depth texture.
    mixin( Property!( _shadowMapTexture ) );
    mixin( Property!( _projView ) );
    mixin( Property!( _shadowMapSize ) );

    this( vec3f color = vec3f( 1.0f ), vec3f direction = vec3f( 0.0f ), bool castShadows = false )
    {
        this.direction = direction;
        super( color );
        this.castShadows = castShadows;
    }

    /// Initializes the lights.
    override void initialize()
    {
        if( castShadows )
        {
            // generate framebuffer for shadow map
            shadowMapFrameBuffer = 0;
            glGenFramebuffers( 1, cast(uint*)&_shadowMapFrameBuffer );
            glBindFramebuffer( GL_FRAMEBUFFER, _shadowMapFrameBuffer );

            // generate depth texture of shadow map
            shadowMapSize = 2048;
            glGenTextures( 1, cast(uint*)&_shadowMapTexture );
            glBindTexture( GL_TEXTURE_2D, _shadowMapTexture );
            glTexImage2D( GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT16, shadowMapSize, shadowMapSize, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

            glFramebufferTexture2D( GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, _shadowMapTexture, 0 );

            // don't want any info besides depth
            glDrawBuffer( GL_NONE );
            // don't want to read from gpu
            glReadBuffer( GL_NONE );

            // check for success
            if( glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE )
            {
                fatal( "Shadow map frame buffer failure." );
                assert(false);
            }
        }
    }

    /**
     * calculates the light's projection and view matrices, and combines them
     */
    void calculateProjView( box3f frustum )
    {
        // determine the center of the frustum
        vec3f center = vec3f( ( frustum.min + frustum.max ).x/2.0f,
                                          ( frustum.min + frustum.max ).y/2.0f,
                                          ( frustum.min + frustum.max ).z/2.0f );

        // determine the rotation for the viewing axis
        // adapted from http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
        vec3f lDirNorm = direction.normalized;
        vec3f baseAxis = vec3f( 0, 0, -1 );
        float cosTheta = dot( lDirNorm, baseAxis );
        float halfCosX2 = sqrt( 0.5f * (1.0f + cosTheta) ) * 2.0f;
        vec3f w = cross( lDirNorm, baseAxis );
        quatf rotation = quatf( halfCosX2/2, w.x / halfCosX2, w.y / halfCosX2, w.z / halfCosX2 );

        // determine the x,y,z axes
        vec3f eulers = rotation.toEulerAngles();
        float cosPitch = cos( eulers.x );
        float sinPitch = sin( eulers.x );
        float cosYaw = cos( eulers.y );
        float sinYaw = sin( eulers.y );
        vec3f xaxis = vec3f( cosYaw, 0.0f, -sinYaw );
        vec3f yaxis = vec3f( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
        vec3f zaxis = vec3f( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

        // build the view matrix
        mat4f viewMatrix;
        ///*
        viewMatrix[ 0 ] = vec4f( xaxis, -xaxis.dot( center ) ).vector;
        viewMatrix[ 1 ] = vec4f( yaxis, -yaxis.dot( center ) ).vector;
        viewMatrix[ 2 ] = vec4f( zaxis, -zaxis.dot( center ) ).vector;
        viewMatrix[ 3 ] = vec4f( 0, 0, 0, 1 ).vector;
        /*/
        // using lookAt works for everying but a light direction of (0,+/-1,0)
        light.view = Camera.lookAt( center - light.direction.normalized, center ); //*/

        // get frustum in view space
        frustum.min = (viewMatrix * vec4f(frustum.min,1.0f)).xyz;
        frustum.max = (viewMatrix * vec4f(frustum.max,1.0f)).xyz;

        // get mins and maxes in view space
        vec3f mins, maxes;
        for( int i = 0; i < 3; i++ )
        {
            if( frustum.min.vector[ i ] < frustum.max.vector[ i ] )
            {
                mins.vector[ i ] = frustum.min.vector[ i ];
                maxes.vector[ i ] = frustum.max.vector[ i ];
            }
            else
            {
                mins.vector[ i ] = frustum.max.vector[ i ];
                maxes.vector[ i ] = frustum.min.vector[ i ];
            }
        }

        float magicNumber = 1.5f; // literally the worst
        projView = mat4f.orthographic( mins.x * magicNumber, maxes.x* magicNumber, mins.y* magicNumber , maxes.y* magicNumber, maxes.z* magicNumber, mins.z* magicNumber ) * viewMatrix;
    }
}

/**
 * Point Light
 */
class PointLight : Light
{
private:
    mat4f _matrix;

public:
    /// The area that lighting will be calculated for.
    @rename( "Radius" )
    float radius;
    /// The light's exponential attenuation modifier.
    @rename( "FalloffRate" )
    float falloffRate;

    this( vec3f color = vec3f( 1.0f ), float radius = 0.0f, float falloffRate = 0.0f )
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
    public mat4f getTransform()
    {
        _matrix = mat4f.identity;
        // Scale
        _matrix[ 0 ][ 0 ] = radius;
        _matrix[ 1 ][ 1 ] = radius;
        _matrix[ 2 ][ 2 ] = radius;
        // Translate
        vec3f position = owner.transform.worldPosition;
        _matrix[ 0 ][ 3 ] = position.x;
        _matrix[ 1 ][ 3 ] = position.y;
        _matrix[ 2 ][ 3 ] = position.z;
        return _matrix;
    }

}

/**
 * SpotLight Stub
 */
class SpotLight : Light
{
public:
    this( vec3f color = vec3f() )
    {
        super( color );
    }
}
