module math.transform;
import core.properties;
import math.vector, math.matrix, math.quaternion;

import std.signals, std.conv;

class Transform
{
public:
	Transform parent;

	this()
	{
		position = new Vector!3;
		rotation = new Quaternion;
		scale = new Vector!3;

		position.connect( &emit );
		rotation.connect( &emit );
		scale.connect( &emit );
	}

	~this()
	{
		destroy( position );
		destroy( rotation ); 
		destroy( scale );
	}

	void rotate( Quaternion rotation )
	{

	}

	void rotate( const float x, const float y, const float z, const float angle )
	{
		rotate( new Quaternion( x, y, z, angle ) );
	}

	void rotate( Vector!3 eulerAngles )
	{
		rotate( eulerAngles.x, eulerAngles.y, eulerAngles.z );
	}

	void rotate( const float x, const float y, const float z )
	{

	}

	void translate( Vector!3 displacement )
	{
		translate( displacement.x, displacement.y, displacement.z );
	}

	void translate( const float x, const float y, const float z )
	{

	}

	mixin( EmmittingProperty!( "Vector!3", "position" ) );
	mixin( EmmittingProperty!( "Quaternion", "rotation" ) );
	mixin( EmmittingProperty!( "Vector!3", "scale" ) );

	mixin Signal!( string, string );
}
