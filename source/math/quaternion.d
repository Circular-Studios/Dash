module math.quaternion;
import core.global;
import math.matrix;

import std.signals, std.conv;

class Quaternion
{
public:
	this()
	{
		this( 0.0f, 0.0f, 0.0f, 1.0f );
	}

	this( const float x, const float y, const float z, const float angle )
	{
		_x = x;
		_y = y;
		_z = z;
		_w = w;

		connect( &this.updateMatrix );
	}

	mixin Signal!( string, string );

	mixin( EmmittingProperty!( "float", "x", "public" ) );
	mixin( EmmittingProperty!( "float", "y" ) );
	mixin( EmmittingProperty!( "float", "z" ) );
	mixin( EmmittingProperty!( "float", "w" ) );

	mixin( Property!( "Matrix!4", "viewMatrix" ) );

private:
	void updateMatrix( string name, string newVal )
	{
		viewMatrix.matrix[ 0 ][ 0 ] = 1.0f - 2.0f * y * y - 2.0f * z * z;
		viewMatrix.matrix[ 0 ][ 1 ] = 2.0f * x * y - 2.0f * z * w;
		viewMatrix.matrix[ 0 ][ 2 ] = 2.0f * x * z + 2.0f * y * w;
		viewMatrix.matrix[ 1 ][ 0 ] = 2.0f * x * y + 2.0f * z * w;
		viewMatrix.matrix[ 1 ][ 1 ] = 1.0f - 2.0f * x * x - 2.0f * z * z;
		viewMatrix.matrix[ 1 ][ 2 ] = 2.0f * y * z - 2.0f * x * w;
		viewMatrix.matrix[ 2 ][ 0 ] = 2.0f * x * z - 2.0f * y * w;
		viewMatrix.matrix[ 2 ][ 1 ] = 2.0f * y * z + 2.0f * x * w;
		viewMatrix.matrix[ 2 ][ 2 ] = 1.0f - 2.0f * x * x - 2.0f * y * y;
	}
}
