/**
 * Defines the Camera class, which controls the view matrix for the world.
 */
module components.camera;
import core.properties, core.gameobject;
import components.component;
import graphics.shaders.shader;
import math.matrix, math.vector;

import std.signals, std.conv;

final class Camera : Component
{
public:
	/**
	 * The view matrix of the camera.
	 */
	mixin DirtyProperty!( "Matrix!4", "viewMatrix", "updateViewMatrix" );
	
	mixin Signal!( string, string );

	this( GameObject owner )
	{
		super( owner );

		owner.transform.connect( &this.setMatrixDirty );
	}

	override void update() { }
	override void draw( Shader shader ) { }
	override void shutdown() { }

	static Matrix!4 lookAtLH( Vector!3 cameraPosition, Vector!3 cameraTarget, Vector!3 cameraUpVector )
	{
		auto zaxis = ( cameraTarget - cameraPosition ).normalize();
		auto xaxis = ( cameraUpVector % zaxis ).normalize();
		auto yaxis = zaxis % xaxis;

		auto newMatrix = new Matrix!4();

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

private:
	final void setMatrixDirty( string prop, string newVal )
	{
		_viewMatrixIsDirty = true;
	}
	final void updateViewMatrix()
	{
		auto up = owner.transform.rotation.matrix * Vector!3.up;
		auto lookAt = ( owner.transform.rotation.matrix * Vector!3.forward ) + owner.transform.position;

		Vector!3[3] axes;
		axes[ 2 ] = ( lookAt - owner.transform.position ).normalize();
		axes[ 0 ] = up.cross( axes[ 2 ] ).normalize();
		axes[ 1 ] = axes[ 2 ].cross( axes[ 0 ] ).normalize();
		
		for( uint ii = 0; ii < 3; ++ii )
		{
			for( uint jj = 0; jj < 3; ++jj )
				viewMatrix.matrix[ jj ][ ii ] = axes[ ii ].values[ jj ];
			viewMatrix.matrix[ 3 ][ ii ] = -axes[ ii ].dot( owner.transform.position );
		}
	}
}
