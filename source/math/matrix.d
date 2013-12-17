module math.matrix;
import math.vector;
import std.math;

class Matrix( uint S = 4 ) if( S > 1 && S < 5 )
{
public:
static
{
	const Matrix!S identity = new Matrix!S;
	Matrix!4 buildPerspective( const float fov, const float screenAspect, const float near, const float depth )
	{
		auto toReturn = new Matrix!4;

		toReturn.matrix[ 0 ][ 0 ] = 1.0f / ( screenAspect * tan( fov / 2.0f ) );
		toReturn.matrix[ 1 ][ 1 ] = 1.0f / tan( fov / 2.0f );
		toReturn.matrix[ 2 ][ 2 ] = depth / ( depth - near );
		toReturn.matrix[ 2 ][ 3 ] = 1.0f;
		toReturn.matrix[ 3 ][ 2 ] = ( -near * depth ) / ( depth - near );
		toReturn.matrix[ 3 ][ 3 ] = 0.0f;

		return toReturn;
	}

	Matrix!4 buildOrthogonal( const float width, const float height, const float near, const float far )
	{
		auto toReturn = new Matrix!4;

		toReturn.matrix[ 0 ][ 0 ] = 2.0f / width;
		toReturn.matrix[ 1 ][ 1 ] = 2.0f / height;
		toReturn.matrix[ 2 ][ 2 ] = -2.0f / ( far - near );
		toReturn.matrix[ 3 ][ 3 ] = 1.0f;

		return toReturn;
	}
}

	this()
	{
		for( uint ii = 0; ii < S; ++ii )
		{
			for( uint jj = 0; jj < S; ++jj )
				matrix[ ii ][ jj ] = 0.0f;

			matrix[ ii ][ ii ] = 1.0f;
		}
	}

	/**
		Calls other operators, and assigns results back to itself
	*/
	Matrix!S opOpAssign( string op )( const Matrix!S other )
	{
		matrix = opBinary!( op[ 0 ] )( other ).matrix;
		return this;
	}

	Matrix!S opBinary( string op : "*" )( const Matrix!S other ) pure
	{
		return mulitiply( other );
	}
	Matrix!S multiply( const Matrix!S other ) pure
	{
		auto result = new Matrix!S;

		for( uint yy = 0; yy < S; ++yy )
		{
			for( uint xx = 0; xx < S; ++xx )
			{
				float value = 0;

				for( uint ii = 0; ii < S; ++ii )
					value += matrix[ ii ][ yy ] * other.matrix[ xx ][ ii ];

				result.matrix[ xx ][ yy ] = value;
			}
		}

		return result;
	}

	Vector!T opBinary( string op : "*", uint T )( const Vector!T other ) pure
	{
		return multiply( other );
	}
	Vector!T multiply( uint T )( const Vector!T other ) pure
	{
		auto result = new Vector!T;

		for( uint ii = 0; ii < T; ++ii )
			for( uint jj = 0; jj < T; ++jj )
				result.values[ ii ] += matrix[ jj ][ ii ] * other.values[ jj ];

		return result;
	}

	Matrix!S opBinary( string op : "+" )( const Matrix!S other ) pure
	{
		return add( other );
	}
	Matrix!S add( const Matrix!S other ) pure
	{
		auto result = new Matrix!S;

		for( uint yy = 0; yy < S; ++yy )
			for( uint xx = 0; xx < S; ++xx )
				result.matrix[ xx ][ yy ] = matrix[ xx ][ yy ] + other.matrix[ xx ][ yy ];

		return result;
	}

	Matrix!S opUnary( string op : "-" )() pure
	{
		return inverse();
	}
	Matrix!S inverse() pure
	{
		return new Matrix!S;
	}

	Matrix!S transpose() pure
	{
		auto result = new Matrix!S;

		for( uint yy = 0; yy < S; ++yy )
			for( uint xx = 0; xx < S; ++xx )
				result.matrix[ xx ][ yy ] = matrix[ yy ][ xx ];

		return result;
	}

	/*Vector!S multiply() pure
	{

	}*/
	
	float[ S ][ S ]	matrix;
}
