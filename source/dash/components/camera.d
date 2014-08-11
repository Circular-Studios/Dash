/**
 * Defines the Camera class, which manages a view and projection matrix.
 */
module dash.components.camera;
import dash.core, dash.components, dash.graphics, dash.utility;

import gfm.math.vector: vec2f, vec3f;
import gfm.math.matrix: mat4f;
import std.conv;

mixin( registerComponents!q{dash.components.camera} );

/**
 * Camera manages a view and projection matrix.
 */
@yamlComponent( "Camera" )
final class Camera : Component, IDirtyable
{
private:
    float _prevFov, _prevNear, _prevFar, _prevWidth, _prevHeight;


    vec2f _projectionConstants; // For rebuilding linear Z in shaders
    mat4f _prevLocalMatrix;
    mat4f _viewMatrix;
    mat4f _inverseViewMatrix;
    mat4f _perspectiveMatrix;
    mat4f _inversePerspectiveMatrix;
    mat4f _orthogonalMatrix;
    mat4f _inverseOrthogonalMatrix;

public:
    /// TODO
    mixin( ThisDirtyGetter!( _viewMatrix, updateViewMatrix ) );
    /// TODO
    mixin( ThisDirtyGetter!( _inverseViewMatrix, updateViewMatrix ) );
    @field( "FOV" )
    float fov;
    @field( "Near" )
    float near;
    @field( "Far" )
    float far;

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final vec2f projectionConstants()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _projectionConstants;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4f perspectiveMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _perspectiveMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4f inversePerspectiveMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _inversePerspectiveMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4f orthogonalMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _orthogonalMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final mat4f inverseOrthogonalMatrix()
    {
        if( this.projectionDirty )
        {
            updatePerspective();
            updateOrthogonal();
            updateProjectionDirty();
        }

        return _inverseOrthogonalMatrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final void updateViewMatrix()
    {
        //Assuming pitch & yaw are in radians
        float cosPitch = cos( owner.transform.rotation.pitch );
        float sinPitch = sin( owner.transform.rotation.pitch );
        float cosYaw = cos( owner.transform.rotation.yaw );
        float sinYaw = sin( owner.transform.rotation.yaw );

        vec3f xaxis = vec3f( cosYaw, 0.0f, -sinYaw );
        vec3f yaxis = vec3f( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
        vec3f zaxis = vec3f( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

        _viewMatrix.clear( 0.0f );
        _viewMatrix[ 0 ] = xaxis.v ~ -( xaxis * owner.transform.position );
        _viewMatrix[ 1 ] = yaxis.v ~ -( yaxis * owner.transform.position );
        _viewMatrix[ 2 ] = zaxis.v ~ -( zaxis * owner.transform.position );
        _viewMatrix[ 3 ] = [ 0, 0, 0, 1 ];

        _inverseViewMatrix = _viewMatrix.inverse();
    }

    /**
     * Creates a view matrix looking at a position.
     *
     * Params:
     *  targetPos = The position for the camera to look at.
     *  cameraPos = The camera's position.
     *  worldUp = The up direction in the world.
     *
     * Returns:
     * A right handed view matrix for the given params.
     */
    final static mat4f lookAt( vec3f targetPos, vec3f cameraPos, vec3f worldUp = vec3f(0,1,0) )
    {
        vec3f zaxis = ( cameraPos - targetPos );
        zaxis.normalize;
        vec3f xaxis = cross( worldUp, zaxis );
        xaxis.normalize;
        vec3f yaxis = cross( zaxis, xaxis );

        mat4f result = mat4f.identity;

        result[0][0] = xaxis.x;
        result[1][0] = xaxis.y;
        result[2][0] = xaxis.z;
        result[3][0] = -dot( xaxis, cameraPos );
        result[0][1] = yaxis.x;
        result[1][1] = yaxis.y;
        result[2][1] = yaxis.z;
        result[3][1] = -dot( yaxis, cameraPos );
        result[0][2] = zaxis.x;
        result[1][2] = zaxis.y;
        result[2][2] = zaxis.z;
        result[3][2] = -dot( zaxis, cameraPos );

        return result.transposed;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final override @property bool isDirty()
    {
        auto result = owner.transform.matrix != _prevLocalMatrix;

        _prevLocalMatrix = owner.transform.matrix;

        return result;
    }

private:

    /*
     * Returns whether any of the variables necessary for the projection matrices have changed
     */
    final bool projectionDirty()
    {
        return fov != _prevFov ||
            far != _prevFar ||
            near != _prevNear ||
            cast(float)Graphics.width != _prevWidth ||
            cast(float)Graphics.height != _prevHeight;
    }

    /*
     * Updates the projection constants, perspective matrix, and inverse perspective matrix
     */
    final void updatePerspective()
    {
        _projectionConstants = vec2( ( -far * near ) / ( far - near ), far / ( far - near ) );
        _perspectiveMatrix = mat4.perspective( cast(float)Graphics.width, cast(float)Graphics.height, fov, near, far );
        _inversePerspectiveMatrix = _perspectiveMatrix.inverse();
    }

    /*
     * Updates the orthogonal matrix, and inverse orthogonal matrix
     */
    final void updateOrthogonal()
    {
        _orthogonalMatrix = mat4.identity;

        _orthogonalMatrix[0][0] = 2.0f / Graphics.width;
        _orthogonalMatrix[1][1] = 2.0f / Graphics.height;
        _orthogonalMatrix[2][2] = -2.0f / (far - near);
        _orthogonalMatrix[3][3] = 1.0f;

        _inverseOrthogonalMatrix = _orthogonalMatrix.inverse();
    }

    /*
     * Sets the _prev values for the projection variables
     */
    final void updateProjectionDirty()
    {
        _prevFov = fov;
        _prevFar = far;
        _prevNear = near;
        _prevWidth = cast(float)Graphics.width;
        _prevHeight = cast(float)Graphics.height;
    }
}
