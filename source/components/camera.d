/**
 * Defines the Camera class, which manages a view and projection matrix.
 */
module components.camera;
import core, components, graphics, utility;

import gl3n.linalg;
import std.conv;

/**
 * Camera manages a view and projection matrix.
 */
shared final class Camera : IComponent, IDirtyable
{
private:
    shared float _prevFov, _prevNear, _prevFar, _prevWidth, _prevHeight;

    shared float _fov, _near, _far;
    shared vec2 _projectionConstants; // For rebuilding linear Z in shaders
    shared mat4 _prevLocalMatrix;
    shared mat4 _viewMatrix;
    shared mat4 _inverseViewMatrix;
    shared mat4 _perspectiveMatrix;
    shared mat4 _inversePerspectiveMatrix;
    shared mat4 _orthogonalMatrix;
    shared mat4 _inverseOrthogonalMatrix;

public:
    override void update() { }
    override void shutdown() { }

    /// TODO
    mixin( ThisDirtyGetter!( _viewMatrix, updateViewMatrix ) );
    /// TODO
    mixin( ThisDirtyGetter!( _inverseViewMatrix, updateViewMatrix ) );
    /// TODO
    mixin( Property!( _fov, AccessModifier.Public ) );
    /// TODO
    mixin( Property!( _near, AccessModifier.Public ) );
    /// TODO
    mixin( Property!( _far, AccessModifier.Public ) );
    
    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    final shared(vec2) projectionConstants()
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
    final shared(mat4) perspectiveMatrix()
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
    final shared(mat4) inversePerspectiveMatrix()
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
    final shared(mat4) orthogonalMatrix()
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
    final shared(mat4) inverseOrthogonalMatrix()
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
        shared float cosPitch = cos( owner.transform.rotation.pitch );
        shared float sinPitch = sin( owner.transform.rotation.pitch );
        shared float cosYaw = cos( owner.transform.rotation.yaw );
        shared float sinYaw = sin( owner.transform.rotation.yaw );

        shared vec3 xaxis = shared vec3( cosYaw, 0.0f, -sinYaw );
        shared vec3 yaxis = shared vec3( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
        shared vec3 zaxis = shared vec3( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

        _viewMatrix.clear( 0.0f );
        _viewMatrix[ 0 ] = xaxis.vector ~ -( xaxis * owner.transform.position );
        _viewMatrix[ 1 ] = yaxis.vector ~ -( yaxis * owner.transform.position );
        _viewMatrix[ 2 ] = zaxis.vector ~ -( zaxis * owner.transform.position );
        _viewMatrix[ 3 ] = [ 0, 0, 0, 1 ];
        
        _inverseViewMatrix = cast(shared)_viewMatrix.inverse();
    }

    /**
     * Creates a view matrix looking at a position.
     *
     * Params:
     *  targetPos = The position for the camera to look at.
     *  cameraPos = The camera's position.
     *  cameraUp = The up vector from the camera.
     *
     * Returns: 
     * A right handed view matrix for the given params.
     */
    final static shared(mat4) lookAt( shared vec3 targetPos, shared vec3 cameraPos, shared vec3 cameraUp = vec3(0,1,0) )
    {
        shared vec3 zaxis = ( cameraPos - targetPos );
        zaxis.normalize;
        shared vec3 xaxis = cross( cameraUp, zaxis );
        xaxis.normalize;
        shared vec3 yaxis = cross( zaxis, xaxis );

        shared mat4 result = mat4.identity;

        result[0][0] = xaxis.x;
        result[1][0] = xaxis.y;
        result[2][0] = xaxis.z;
        result[3][0] = -dot( xaxis, cameraPos );
        result[0][1] = yaxis.x;
        result[1][1] = yaxis.y;
        result[2][1] = yaxis.z;
        result[3][0] = -dot( yaxis, cameraPos );
        result[0][2] = zaxis.x;
        result[1][2] = zaxis.y;
        result[2][2] = zaxis.z;
        result[3][2] = -dot( zaxis, cameraPos );

        return result;
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
        return _fov != _prevFov ||
            _far != _prevFar ||
            _near != _prevNear ||
            cast(float)Graphics.width != _prevWidth ||
            cast(float)Graphics.height != _prevHeight;
    }

    /*
     * Updates the projection constants, perspective matrix, and inverse perspective matrix
     */
    final void updatePerspective()
    {
        _projectionConstants = vec2( ( -_far * _near ) / ( _far - _near ), _far / ( _far - _near ) );
        _perspectiveMatrix = shared mat4.perspective( cast(float)Graphics.width, cast(float)Graphics.height, _fov, _near, _far );
        _inversePerspectiveMatrix = cast(shared)_perspectiveMatrix.inverse();
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

        _inverseOrthogonalMatrix = cast(shared)_orthogonalMatrix.inverse();
    }

    /*
     * Sets the _prev values for the projection variables
     */
    final void updateProjectionDirty()
    {
        _prevFov = _fov;
        _prevFar = _far;
        _prevNear = _near;
        _prevWidth = cast(float)Graphics.width;
        _prevHeight = cast(float)Graphics.height;
    }
}

static this()
{
    import yaml;
    IComponent.initializers[ "Camera" ] = ( Node yml, shared GameObject obj )
    {
        obj.camera = new shared Camera;
        obj.camera.owner = obj;

        //float fromYaml;
        if( !Config.tryGet( "FOV", obj.camera._fov, yml ) )
            logFatal( obj.name, " is missing FOV value for its camera. ");
        if( !Config.tryGet( "Near", obj.camera._near, yml ) )
            logFatal( obj.name, " is missing near plane value for its camera. ");
        if( !Config.tryGet( "Far", obj.camera._far, yml ) )
            logFatal( obj.name, " is missing Far plane value for its camera. ");

        obj.camera.updatePerspective();
        obj.camera.updateOrthogonal();
        obj.camera.updateProjectionDirty();

        return obj.camera;
    };
}