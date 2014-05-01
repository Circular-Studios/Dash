/**
 * Contains the base class for all light types, Light, as well as
 * AmbientLight, DirectionalLight, PointLight, SpotLight.
 */
module components.lights;
import core, components, graphics;
import utility;

import gl3n.linalg, gl3n.aabb;
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

    static this()
    {
        IComponent.initializers[ "Light" ] = ( Node yml, shared GameObject obj )
        {
            obj.light = cast(shared)yml.get!Light;
            obj.light.owner = obj;
            return obj.light;
        };
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

/**
 * Directional Light
 */
shared class DirectionalLight : Light
{
private:
    vec3 _direction;
    uint _shadowMapFrameBuffer;
    uint _shadowMapTexture;
    mat4 _projView;
    int _shadowMapSize;

public:
    /// The direction the light points in.
    mixin( Property!( _direction, AccessModifier.Public ) );
    /// The FrameBuffer for the shadowmap.
    mixin( Property!( _shadowMapFrameBuffer ) );
    /// The shadow map's depth texture.
    mixin( Property!( _shadowMapTexture ) );
    mixin( Property!( _projView ) );
    mixin( Property!( _shadowMapSize ) );

    this( shared vec3 color, shared vec3 direction )
    {
        this.direction = direction; 
        super( color );

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

    /**
     * calculates the light's projection and view matrices, and combines them
     */
    void calculateProjView( shared AABB frustum )
    {
        // determine the center of the frustum
        shared vec3 center = shared vec3( ( frustum.min + frustum.max ).x/2.0f,
                                          ( frustum.min + frustum.max ).y/2.0f,
                                          ( frustum.min + frustum.max ).z/2.0f );

        // determine the rotation for the viewing axis
        // adapted from http://lolengine.net/blog/2013/09/18/beautiful-maths-quaternion-from-vectors
        shared vec3 lDirNorm = direction.normalized;
        shared vec3 baseAxis = vec3( 0, 0, -1 );
        shared cosTheta = dot( lDirNorm, baseAxis );
        float halfCosX2 = sqrt( 0.5f * (1.0f + cosTheta) ) * 2.0f;
        shared vec3 w = cross( lDirNorm, baseAxis );
        shared quat rotation = quat( halfCosX2/2, w.x / halfCosX2, w.y / halfCosX2, w.z / halfCosX2 );

        // determine the x,y,z axes
        shared float cosPitch = cos( rotation.pitch );
        shared float sinPitch = sin( rotation.pitch );
        shared float cosYaw = cos( rotation.yaw );
        shared float sinYaw = sin( rotation.yaw );
        shared vec3 xaxis = shared vec3( cosYaw, 0.0f, -sinYaw );
        shared vec3 yaxis = shared vec3( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
        shared vec3 zaxis = shared vec3( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

        // build the view matrix
        shared mat4 viewMatrix;
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
        shared vec3 mins, maxes;
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

        // build the projectionView matrix
        projView = mat4.orthographic( mins.x , maxes.x, mins.y , maxes.y, maxes.z, mins.z ) * viewMatrix;
    }
}

/**
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

/**
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
