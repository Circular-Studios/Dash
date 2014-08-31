/**
 * Contains the base class for all light types, Light, as well as
 * AmbientLight, DirectionalLight, PointLight, SpotLight.
 */
module dash.components.lights;
import dash.core, dash.components, dash.graphics;
import dash.utility;

import gl3n.linalg, gl3n.aabb;
import derelict.opengl3.gl3;

mixin( registerComponents!q{dash.components.lights} );

/**
 * Base class for lights.
 */
abstract class Light : Component
{
private:
    bool _castShadows;

public:
    /// The color the light gives off.
    @field( "Color" )
    vec3 color;
    /// If it should cast shadows
    mixin( Property!( _castShadows ) );

    this( vec3 color )
    {
        this.color = color;
        _castShadows = false;
    }

    override void update() { }
    override void shutdown() { }
}

/**
 * Ambient Light
 */
@yamlComponent()
class AmbientLight : Light
{
    this( vec3 color = vec3() )
    {
        super( color );
    }
}

/**
 * Directional Light
 */
@yamlComponent()
class DirectionalLight : Light
{
private:
    uint _shadowMapFrameBuffer;
    uint _shadowMapTexture;
    mat4 _projView;
    int _shadowMapSize;

public:
    /// The direction the light points in.
    @field( "Direction" )
    vec3 direction;
    /// The FrameBuffer for the shadowmap.
    mixin( Property!( _shadowMapFrameBuffer ) );
    /// The shadow map's depth texture.
    mixin( Property!( _shadowMapTexture ) );
    mixin( Property!( _projView ) );
    mixin( Property!( _shadowMapSize ) );

    this( vec3 color = vec3(), vec3 direction = vec3(), bool castShadows = false )
    {
        this.direction = direction;
        super( color );
        this.castShadows = castShadows;
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
                logFatal("Shadow map frame buffer failure.");
                assert(false);
            }
        }
    }

    /**
     * calculates the light's projection and view matrices, and combines them
     */
    void calculateProjView( AABB frustum )
    {
        // determine the center of the frustum
        vec3 center = vec3( ( frustum.min + frustum.max ).x/2.0f,
                                          ( frustum.min + frustum.max ).y/2.0f,
                                          ( frustum.min + frustum.max ).z/2.0f );

        // determine the rotation for the viewing axis
        // adapted from http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
        vec3 lDirNorm = direction.normalized;
        vec3 baseAxis = vec3( 0, 0, -1 );
        float cosTheta = dot( lDirNorm, baseAxis );
        float halfCosX2 = sqrt( 0.5f * (1.0f + cosTheta) ) * 2.0f;
        vec3 w = cross( lDirNorm, baseAxis );
        quat rotation = quat( halfCosX2/2, w.x / halfCosX2, w.y / halfCosX2, w.z / halfCosX2 );

        // determine the x,y,z axes
        float cosPitch = cos( rotation.pitch );
        float sinPitch = sin( rotation.pitch );
        float cosYaw = cos( rotation.yaw );
        float sinYaw = sin( rotation.yaw );
        vec3 xaxis = vec3( cosYaw, 0.0f, -sinYaw );
        vec3 yaxis = vec3( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
        vec3 zaxis = vec3( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

        // build the view matrix
        mat4 viewMatrix;
        ///*
        viewMatrix.clear(0.0f);
        viewMatrix[ 0 ] = xaxis.vector ~ -( xaxis * center );
        viewMatrix[ 1 ] = yaxis.vector ~ -( yaxis * center );
        viewMatrix[ 2 ] = zaxis.vector ~ -( zaxis * center );
        viewMatrix[ 3 ] = [ 0, 0, 0, 1 ];
        /*/
        // using lookAt works for everying but a light direction of (0,+/-1,0)
        light.view = Camera.lookAt( center - light.direction.normalized, center ); //*/

        // get frustum in view space
        frustum.min = (viewMatrix * vec4(frustum.min,1.0f)).xyz;
        frustum.max = (viewMatrix * vec4(frustum.max,1.0f)).xyz;

        // get mins and maxes in view space
        vec3 mins, maxes;
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
        projView = mat4.orthographic( mins.x * magicNumber, maxes.x* magicNumber, mins.y* magicNumber , maxes.y* magicNumber, maxes.z* magicNumber, mins.z* magicNumber ) * viewMatrix;
    }
}

/**
 * Point Light
 */
@yamlComponent()
class PointLight : Light
{
private:
    mat4 _matrix;

public:
    /// The area that lighting will be calculated for.
    @field( "Radius" )
    float radius;
    /// The light's exponential attenuation modifier.
    @field( "FalloffRate" )
    float falloffRate;

    this( vec3 color = vec3(), float radius = 0.0f, float falloffRate = 0.0f )
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
    public mat4 getTransform()
    {
        _matrix = mat4.identity;
        // Scale
        _matrix[ 0 ][ 0 ] = radius;
        _matrix[ 1 ][ 1 ] = radius;
        _matrix[ 2 ][ 2 ] = radius;
        // Translate
        vec3 position = owner.transform.worldPosition;
        _matrix[ 0 ][ 3 ] = position.x;
        _matrix[ 1 ][ 3 ] = position.y;
        _matrix[ 2 ][ 3 ] = position.z;
        return _matrix;
    }

}

/**
 * SpotLight Stub
 */
@yamlComponent()
class SpotLight : Light
{
public:
    this( vec3 color = vec3() )
    {
        super( color );
    }
}
