module components.camera;
import core.properties, core.gameobject;
import components.icomponent;
import graphics.shaders.ishader;
import math.matrix, math.vector;

import std.signals, std.conv;

class Camera : IComponent
{
public:
	this( GameObject owner )
	{
		super( owner );

		owner.transform.connect( &this.updateViewMatrix );
	}

	mixin( Property!( "Matrix!4", "viewMatrix" ) );

	mixin Signal!( string, string );

private:
	void updateViewMatrix( string name, string newVal )
	{
		auto up = owner.transform.rotation.matrix * Vector!3.up;
		auto lookAt = ( owner.transform.rotation.matrix * Vector!3.forward ) + owner.transform.position;

		Vector!3[3] axes;
		axes[ 2 ] = ( lookAt - owner.transform.position ).normalize();
		axes[ 0 ] = up.cross( axes[ 2 ] ).normalize();
		axes[ 1 ] = axes[ 2 ].cross( axes[ 0 ] );
		
		for( uint ii = 0; ii < 3; ++ii )
		{
			for( uint jj = 0; jj < 3; ++jj )
				viewMatrix.matrix[ jj ][ ii ] = axes[ ii ].values[ jj ];
			viewMatrix.matrix[ 3 ][ ii ] = -axes[ ii ].dot( owner.transform.position );
		}
	}
}
