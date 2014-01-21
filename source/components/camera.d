/**
 * Defines the Camera class, which controls the view matrix for the world.
 */
module components.camera;
import core.properties, core.gameobject;
import components.component;
import graphics.shaders.shader;
import math.matrix, math.vector;

import std.signals, std.conv;

class Camera : Component
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

private:
	void setMatrixDirty( string prop, string newVal )
	{
		_viewMatrixIsDirty = true;
	}
	void updateViewMatrix()
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
