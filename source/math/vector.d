module math.vector;
import core.properties;

import std.math;
import std.signals, std.conv, std.typetuple, std.traits;

class Vector( uint S = 3 )
{
public:
	enum length = S;

	this( float def = 0.0f ) @safe
	{
		for( uint ii = 0; ii < S; ++ii )
			values[ ii ] = def;
	}

	this( float[] arg ... ) @safe
	{
		for( uint ii = 0; ii < S; ++ii )
			values[ ii ] = arg[ ii ];
	}

	/**
	 * Returns a swizzled vector
	 */
	auto opDispatch( string prop )() if( prop.length > 1 )
	{
		auto result = new Vector!( prop.length );

		foreach( index; staticIota!( 0, prop.length ) )
		{
			mixin( "result.values[ index ] = " ~ prop[ index ] ~ ";" );
		}

		return result;
	}

	/**
	 * Calls other operators, and assigns results back to itself
	 */
	Vector!S opOpAssign( string op )( const Vector!S other ) @safe
	{
		values = opBinary!( op[ 0 ] )( other ).values;
		return this;
	}

	override int opCmp( Object o )
	{
		if( typeid(o) != typeid(this) )
			return 1;

		auto other = cast(Vector!S)o;

		for( uint ii = 0; ii < S; ++ii )
		{
			if( values[ ii ] < other.values[ ii ] )
				return -1;
			else if( values[ ii ] > other.values[ ii ] )
				return 1;
		}

		return 0;
	}

	/// Alias for operators
	static if( S == 3 )
		alias opBinary!"%" cross;
	alias opBinary!"*" dot;
	alias opBinary!"+" add;
	alias opBinary!"-" subtract;

	/**
	 * Responsible for all math functions related to Vector.
	 */
	auto opBinary( string op, T = Vector!S )( T other )
	{
		static if ( is( Unqual!T == Vector!S ) )
		{
			static if ( op == "*" )
			{
				float result = 0;
				
				foreach ( ii; 0..S )
					result += values[ ii ] * other.values[ ii ];

				return result;
			}
			else static if ( op == "%" && S == 3 )
			{
				auto result = new Vector!S;

				result.x = ( y * other.z ) - ( z * other.y );
				result.y = ( z * other.x ) - ( x * other.z );
				result.z = ( x * other.y ) - ( y * other.x );

				return result;
			}
			else static if ( op == "+" )
			{
				auto result = new Vector!S;

				for( uint ii = 0; ii < S; ++ii )
					result.values[ ii ] = values[ ii ] + other.values[ ii ];

				return result;
			}
			else static if ( op == "-" )
			{
				auto result = new Vector!S;

				for( uint ii = 0; ii < S; ++ii )
					result.values[ ii ] = values[ ii ] - other.values[ ii ];

				return result;
			}
			else static assert( 0, "Operator " ~ op ~ " not implemented." );
		}
		else static if( is( Unqual!T == float ) )
		{
			static if ( op == "*" )
			{
				auto result = new Vector!S;

				for( uint ii = 0; ii < S; ++ii )
					result.values[ ii ] += values[ ii ] * other.values[ ii ];

				return result;
			}
			else static assert( 0, "Operator " ~ op ~ " not implemented." );
		}
		else static assert( 0, "Operator " ~ op ~ " not implemented for type " ~ T.stringof ~ "." );
	}

	Vector!S opUnary( string op )() pure @safe
	{
		static if ( op == "-" )
		{
			auto result = new Vector!S;

			for( uint ii = 0; ii < S; ++ii )
				result.values[ ii ] = -values[ ii ];

			return result;
		}
		else static assert ( 0, "Operator " ~ op ~ " not implemented." );
	}

	float magnitude() pure @safe
	{
		float result = 0.0f;

		for( uint ii = 0; ii < S; ++ii )
			result += values[ ii ] * values[ ii ];

		result = sqrt( result );

		return result;
	}

	Vector!S normalize() pure @safe
	{
		auto result = new Vector!S;
		auto mag = magnitude();

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] = values[ ii ] / mag;

		return result;
	}

	// Set named accessors
	static if( S >= 2 )
	{
		mixin EmmittingBackedProperty!( "float", "values[0]", "x", "public" );
		mixin EmmittingBackedProperty!( "float", "values[1]", "y", "public" );
	}
	static if( S >= 3 )
	{
		mixin EmmittingBackedProperty!( "float", "values[2]", "z", "public" );
	}
	static if( S >= 4 )
	{
		mixin EmmittingBackedProperty!( "float", "values[3]", "w", "public" );
	}

	// Set predefined constants
	static if( S == 2 )
	{
		static const Vector!2 up = new Vector!2( 0.0f, 1.0f );
		static const Vector!2 right = new Vector!2( 1.0f, 0.0f );
	}
	static if( S == 3 )
	{
		static const Vector!3 up = new Vector!3( 0.0f, 1.0f, 0.0f );
		static const Vector!3 forward = new Vector!3( 0.0f, 0.0f, 1.0f );
		static const Vector!3 right = new Vector!3( 1.0f, 0.0f, 0.0f );
	}

	/// Stores the values in the vector
	float[ S ] values;

	mixin Signal!( string, string );
}

// Creates a range from start inclusive to end exclusive.
template staticIota(size_t start, size_t end)
{
	static if(start == end)
		alias TypeTuple!() staticIota;
	else static if(start < end)
		alias TypeTuple!(start, staticIota!(start + 1, end)) staticIota;
	else
		static assert(0, "start cannot be greater then end!");
}

unittest
{
	import std.stdio;
	writeln( "Dash Vector opDispatch unittest" );

	auto vec1 = new Vector!3( 1.0f, 2.0f, 3.0f );

	auto vec2 = vec1.zyx;

	assert( vec2.x == vec1.z );
	assert( vec2.y == vec1.y );
	assert( vec2.z == vec1.x );
}
unittest
{
	import std.stdio;
	writeln( "Dash Vector magnitude unittest" );

	auto vec2 = new Vector!2( 1.0f, 0.0f );
	assert( vec2.magnitude == 1.0f );

	auto vec3 = new Vector!3( 0.0f, 2.0f, 0.0f );
	assert( vec3.magnitude == 2.0f );

	auto vec4 = new Vector!4( 0.0f, 0.0f, 3.0f, 0.0f );
	assert( vec4.magnitude == 3.0f );
}
