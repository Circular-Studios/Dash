module math.matrix;
import math.vector;
import std.math, std.numeric, std.traits;

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

	this() pure @safe
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

	alias opBinary!"*" multiply;

	/**
	* Responsible for all math functions related to Matrix.
	*/
	auto opBinary( string op, T = Matrix!S )( T other )
	{
		static if ( is( Unqual!T == Matrix!S ) )
		{
			static if ( op == "*" )
			{
				// From here: http://rosettacode.org/wiki/Matrix_multiplication#Stronger_Statically_Typed_Version
				auto result = new Matrix!S;
				float[ S ] aux;

				foreach ( j; 0..S )
				{
					foreach ( i, bi; other.matrix )
						aux[ i ] = bi[ j ];
					foreach ( i, ai; matrix )
						result.matrix[ i ][ j ] = dotProduct( ai, aux );
				}

				return result;
			}
			else static if ( op == "+" )
			{
				auto result = new Matrix!S;
				
				foreach ( yy; 0..S )
					foreach ( xx; 0..S )
						result.matrix[ xx ][ yy ] = matrix[ xx ][ yy ] + other.matrix[ xx ][ yy ];
			}
			else static assert( 0, "Operator " ~ op ~ " not implemented." );
		}
		else static if ( is( Unqual!T == float ) )
		{
			static if ( op == "*" )
			{
				auto result = Matrix!S;

				foreach ( yy, row; matrix )
					foreach ( xx, element; row )
						result.matrix[ xx ][ yy ] = element * other;
				
				return result;
			}
		}
		// Is vector?
		else static if ( __traits(compiles, T.length) && T.length <= S )
		{
			// Deduce Vector length
			foreach( VS; staticIota!( 0, S ) )
			{
				static if ( __traits(compiles, T.length) && VS == T.length && is( Unqual!T == Vector!VS ) )
				{
					static if ( op == "*" )
					{
						auto result = new Vector!VS;

						for( uint ii = 0; ii < VS; ++ii )
							for( uint jj = 0; jj < VS; ++jj )
								result.values[ ii ] += matrix[ jj ][ ii ] * other.values[ jj ];

						return result;
					}
					else static assert( 0, "Operator " ~ op ~ " not implemented." );
				}
			}

			// Incase of fall though, break at run time.
			// This shouldn't ever get hit.
			assert( false );
		}
		else static assert( 0, "Operator " ~ op ~ " not implemented." );
	}

	Matrix!S opUnary( string op : "-" )() pure @safe
	{
		return inverse();
	}
	Matrix!S inverse() pure @safe
	{
		return new Matrix!S;
	}

	Matrix!S transpose() pure @safe
	{
		auto result = new Matrix!S;

		for( uint yy = 0; yy < S; ++yy )
			for( uint xx = 0; xx < S; ++xx )
				result.matrix[ xx ][ yy ] = matrix[ yy ][ xx ];

		return result;
	}
	
	float[ S ][ S ]	matrix;
}
