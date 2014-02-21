/**
 * Defines the Camera class, which controls the view matrix for the world.
 */
module components.camera;
import core.properties, core.gameobject;
import components.component;
import graphics.shaders;

import gl3n.linalg;

import std.signals, std.conv;

final class Camera : Component
{
public:	
	mixin Signal!( string, string );

	this( GameObject owner )
	{
		super( owner );

		owner.transform.connect( &this.setMatrixDirty );
	}

	override void update() { }
	override void shutdown() { }

	final @property mat4 viewMatrix()
	{
		if( _viewMatrixIsDirty )
			updateViewMatrix();

		return _viewMatrix;
	}

private:
	mat4 _viewMatrix;
	bool _viewMatrixIsDirty;
	final void setMatrixDirty( string prop, string newVal )
	{
		_viewMatrixIsDirty = true;
	}
	final void updateViewMatrix()
	{
		//Assuming pitch & yaw are in radians
		float cosPitch = cos( owner.transform.rotation.pitch );
		float sinPitch = sin( owner.transform.rotation.pitch );
		float cosYaw = cos( owner.transform.rotation.yaw );
		float sinYaw = sin( owner.transform.rotation.yaw );

		vec3 xaxis = vec3( cosYaw, 0.0f, -sinYaw );
		vec3 yaxis = vec3( sinYaw * sinPitch, cosPitch, cosYaw * sinPitch );
		vec3 zaxis = vec3( sinYaw * cosPitch, -sinPitch, cosPitch * cosYaw );

		_viewMatrix.clear( 0.0f );
		_viewMatrix[ 0 ] = [ xaxis.x, yaxis.x, zaxis.x, 0 ];
		_viewMatrix[ 1 ] = [ xaxis.y, yaxis.y, zaxis.y, 0 ];
		_viewMatrix[ 2 ] = [ xaxis.z, yaxis.z, zaxis.z, 0 ];
		_viewMatrix[ 3 ] = [ -( xaxis * owner.transform.position ), -( yaxis * owner.transform.position ), -( zaxis * owner.transform.position ), 1 ];

		_viewMatrixIsDirty = false;
	}
}
