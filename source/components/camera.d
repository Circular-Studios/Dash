/**
 * Defines the Camera class, which controls the view matrix for the world.
 */
module components.camera;
import core, components, graphics, utility;

import gl3n.linalg;
import std.conv;

/**
 * Camera manages the viewmatrix and audio listeners for the world.
 */
shared final class Camera : IComponent, IDirtyable
{
private:
    float _fov, _near, _far;
    mat4 _prevLocalMatrix;
    mat4 _viewMatrix;

public:
    override void update() { }
    override void shutdown() { }

    mixin( ThisDirtyGetter!( _viewMatrix, updateViewMatrix ) );

    mixin( Property!( _fov, AccessModifier.Public ) );
    mixin( Property!( _near, AccessModifier.Public )  );
    mixin( Property!( _far, AccessModifier.Public )  );

    final shared(mat4) buildPerspective( float width, float height )
    {
        return mat4.perspective( width, height, _fov, _near, _far );
    }

    final shared(mat4) buildOrthogonal( float width, float height )
    {
        mat4 toReturn = mat4.identity;

        toReturn[0][0] = 2.0f / width; 
        toReturn[1][1] = 2.0f / height;
        toReturn[2][2] = -2.0f / (far - near);
        toReturn[3][3] = 1.0f;

        return toReturn;
    }

    final void updateViewMatrix()
    {
        //Assuming pitch & yaw are in radians
        float cosPitch = cos( owner.transform.rotation.pitch );
        float sinPitch = sin( owner.transform.rotation.pitch );
        float cosYaw = cos( owner.transform.rotation.yaw );
        float sinYaw = sin( owner.transform.rotation.yaw );

        shared vec3 xaxis = shared vec3( cosYaw, 0.0f, -sinYaw );
        shared vec3 yaxis = shared vec3( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
        shared vec3 zaxis = shared vec3( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

        _viewMatrix.clear( 0.0f );
        _viewMatrix[ 0 ] = xaxis.vector ~ -( xaxis * owner.transform.position );
        _viewMatrix[ 1 ] = yaxis.vector ~ -( yaxis * owner.transform.position );
        _viewMatrix[ 2 ] = zaxis.vector ~ -( zaxis * owner.transform.position );
        _viewMatrix[ 3 ] = [ 0, 0, 0, 1 ];
    }

    final override @property bool isDirty()
    {
        auto result = owner.transform.matrix != _prevLocalMatrix;

        _prevLocalMatrix = owner.transform.matrix;

        return result;
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
            logError( obj.name, " is missing FOV value for its camera. ");
        if( !Config.tryGet( "Near", obj.camera._near, yml ) )
            logError( obj.name, " is missing near plane value for its camera. ");
        if( !Config.tryGet( "Far", obj.camera._far, yml ) )
            logError( obj.name, " is missing Far plane value for its camera. ");

        return obj.camera;
    };
}
