module math.quaternion;
import core.properties;
import math.matrix;

import std.signals, std.conv;
import std.math;

class Quaternion
{
public:
	this()
	{
		this( 0.0f, 0.0f, 0.0f, 1.0f );
	}

	this( const float x, const float y, const float z, const float angle )
	{
		immutable float fHalfAngle = angle / 2.0f;
		immutable float fSin = sin( fHalfAngle );

		_w = cos( fHalfAngle );
		_x = fSin * x;
		_y = fSin * y;
		_z = fSin * z;
	}

	mixin Signal!( string, string );

	mixin( EmmittingPropertySetDirty!( "float", "x", "matrix", "public" ) );
	mixin( EmmittingPropertySetDirty!( "float", "y", "matrix", "public" ) );
	mixin( EmmittingPropertySetDirty!( "float", "z", "matrix", "public" ) );
	mixin( EmmittingPropertySetDirty!( "float", "w", "matrix", "public" ) );

	mixin( DirtyProperty!( "Matrix!4", "matrix", "updateMatrix" ) );

	Quaternion opBinary( string op ) ( Quaternion rhs )
	{
		static if ( op  == "*" )
		{
			return Quaternion( /* TO DO */ );
		}
		else static assert ( 0, "Operator " ~ op ~ " not implemented " );
	}

	ref Quaternion opOpAssign( string op ) ( Quaternion rhs )
	{
		static if ( op == "*" )
		{
			x = 0;
			y = 0;
			z = 0;
			w = 0;
			/* TO DO */
			return this;
		}
		else static assert ( 0, "Operator " ~ op ~ " not implemented for assign " );
	}

	Matrix!4 ToRotationMatrix() 
	{
		return new Matrix!4( /* TO DO */ );
	}

private:
	void updateMatrix()
	{
		matrix.matrix[ 0 ][ 0 ] = 1.0f - 2.0f * y * y - 2.0f * z * z;
		matrix.matrix[ 0 ][ 1 ] = 2.0f * x * y - 2.0f * z * w;
		matrix.matrix[ 0 ][ 2 ] = 2.0f * x * z + 2.0f * y * w;
		matrix.matrix[ 1 ][ 0 ] = 2.0f * x * y + 2.0f * z * w;
		matrix.matrix[ 1 ][ 1 ] = 1.0f - 2.0f * x * x - 2.0f * z * z;
		matrix.matrix[ 1 ][ 2 ] = 2.0f * y * z - 2.0f * x * w;
		matrix.matrix[ 2 ][ 0 ] = 2.0f * x * z - 2.0f * y * w;
		matrix.matrix[ 2 ][ 1 ] = 2.0f * y * z + 2.0f * x * w;
		matrix.matrix[ 2 ][ 2 ] = 1.0f - 2.0f * x * x - 2.0f * y * y;
	}
}
