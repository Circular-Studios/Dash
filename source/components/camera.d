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
	/**
	 * The view matrix of the camera.
	 */
	mixin DirtyProperty!( "mat4", "viewMatrix", "updateViewMatrix" );
	
	mixin Signal!( string, string );

	this( GameObject owner )
	{
		super( owner );

		owner.transform.connect( &this.setMatrixDirty );
	}

	override void update() { }
	override void shutdown() { }

	static mat4 lookAtLH( vec3 cameraTarget, vec3 cameraUpVector, vec3 cameraPosition )
	{
		auto zaxis = ( cameraTarget - cameraPosition ).normalized();
		auto xaxis = cross( cameraUpVector, zaxis ).normalized();
		auto yaxis = cross( zaxis, xaxis );

		mat4 newMatrix;

		newMatrix.matrix[0][0] = xaxis.x;
		newMatrix.matrix[1][0] = xaxis.y;
		newMatrix.matrix[2][0] = xaxis.z;
		newMatrix.matrix[0][1] = yaxis.x;
		newMatrix.matrix[1][1] = yaxis.y;
		newMatrix.matrix[2][1] = yaxis.z;
		newMatrix.matrix[0][2] = zaxis.x;
		newMatrix.matrix[1][2] = zaxis.y;
		newMatrix.matrix[2][2] = zaxis.z;
		newMatrix.matrix[3][0] = -( xaxis * cameraPosition );
		newMatrix.matrix[3][1] = -( yaxis * cameraPosition );
		newMatrix.matrix[3][2] = -( zaxis * cameraPosition );
		newMatrix.matrix[3][3] = 1.0f;

		return newMatrix;
	}

	static mat4 buildPerspective( const float fov, const float screenAspect, const float near, const float depth )
	{
		mat4 toReturn;
		toReturn.clear( 0 );
		auto yScale = 1 / tan( fov / 2 );
		auto xScale = yScale / screenAspect;

		toReturn[ 0 ][ 0 ] = xScale;
		toReturn[ 1 ][ 1 ] = yScale;
		toReturn[ 2 ][ 2 ] = depth / ( depth - near );
		toReturn[ 2 ][ 3 ] = 1.0f;
		toReturn[ 3 ][ 2 ] = ( -near * depth ) / ( depth - near );
		toReturn[ 3 ][ 3 ] = 0.0f;

		return toReturn.transposed();
	}

private:
	final void setMatrixDirty( string prop, string newVal )
	{
		_viewMatrixIsDirty = true;
	}
	final void updateViewMatrix()
	{
		/*auto up = owner.transform.rotation.to_matrix( 4, 4 ) * new vec3( 0, 1, 0 );
		auto lookAt = ( owner.transform.rotation.to_matrix( 4, 4 ) * new vec3( 0, 0, 1 ) ) + owner.transform.position;

		vec3[3] axes;
		axes[ 2 ] = ( lookAt - owner.transform.position ).normalize();
		axes[ 0 ] = up.cross( axes[ 2 ] ).normalize();
		axes[ 1 ] = axes[ 2 ].cross( axes[ 0 ] ).normalize();
		
		for( uint ii = 0; ii < 3; ++ii )
		{
			for( uint jj = 0; jj < 3; ++jj )
				viewMatrix[ jj ][ ii ] = axes[ ii ][ jj ];
			viewMatrix[ 3 ][ ii ] = -axes[ ii ].dot( owner.transform.position );
		}*/
	}
}
