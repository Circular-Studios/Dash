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
shared final class Camera : IComponent
{
private:
	float _fov, _near, _far;
	mat4 _viewMatrix;
public:
	override void update() { }
	override void shutdown() { }

	mixin( Property!( _viewMatrix, AccessModifier.Public ) );

	mixin( Property!( _fov, AccessModifier.Public ) );
	mixin( Property!( _near, AccessModifier.Public )  );
	mixin( Property!( _far, AccessModifier.Public )  );

	final mat4 buildPerspective( float width, float height )
	{
		return mat4.perspective( width, height, _fov, _near, _far );
	}

	final mat4 buildOrthogonal( float width, float height )
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
		float cosPitch = cos( (cast()owner.transform.rotation).pitch );
		float sinPitch = sin( (cast()owner.transform.rotation).pitch );
		float cosYaw = cos( (cast()owner.transform.rotation).yaw );
		float sinYaw = sin( (cast()owner.transform.rotation).yaw );

		vec3 xaxis = vec3( cosYaw, 0.0f, -sinYaw );
		vec3 yaxis = vec3( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
		vec3 zaxis = vec3( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

		(cast()_viewMatrix).clear( 0.0f );
		_viewMatrix[ 0 ] = xaxis.vector ~ -( xaxis * cast()owner.transform.position );
		_viewMatrix[ 1 ] = yaxis.vector ~ -( yaxis * cast()owner.transform.position );
		_viewMatrix[ 2 ] = zaxis.vector ~ -( zaxis * cast()owner.transform.position );
		_viewMatrix[ 3 ] = [ 0, 0, 0, 1 ];
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
