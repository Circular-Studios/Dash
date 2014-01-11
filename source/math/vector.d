module math.vector;
import core.properties;

import std.math;
import std.signals, std.conv, std.typetuple;

class Vector( uint S = 3 )
{
public:
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
	unittest
	{
		auto vec1 = new Vector!3( 1.0f, 2.0f, 3.0f );

		auto vec2 = vec1.zyx;

		assert( vec2.x == vec1.z );
		assert( vec2.y == vec1.y );
		assert( vec2.z == vec1.x );
	}

	/**
		Calls other operators, and assigns results back to itself
	*/
	Vector!S opOpAssign( string op )( const Vector!S other ) @safe
	{
		values = opBinary!( op[ 0 ] )( other ).values;
		return this;
	}

	float dot( const Vector!S other ) pure @safe
	{
		float result = 0.0f;

		for( uint ii = 0; ii < S; ++ii )
			result += ( values[ ii ] * other.values[ ii ] );

		return result;
	}

	//Vector!S cross( const Vector!S other ) pure
	//{
	//    auto result = new Vector!S;
	//
	//    for( uint ii = 0; ii < S; ++ii )
	//    {
	//        uint index1 = ( ii + 2 ) % S;
	//        uint index2 = ( ii + 2 ) % S;
	//        result.values[ ii ] =
	//            ( values[ index1 ] * other.values[ index2 ] ) -
	//            ( values[ index2 ] * other.values[ index1 ] );
	//    }
	//
	//    return result;
	//}

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

	Vector!S opBinary( string op : "*" )( const float other ) pure @safe
	{
		return multiply( other );
	}
	Vector!S multiply( const Vector!S other ) pure @safe
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] += values[ ii ] * other.values[ ii ];

		return result;
	}

	Vector!S opBinary( string op : "+" )( const Vector!S other ) pure @safe
	{
		return add( other );
	}
	Vector!S add( const Vector!S other ) pure @safe
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] = values[ ii ] + other.values[ ii ];

		return result;
	}

	Vector!S opBinary( string op : "-" )( const Vector!S other ) pure @safe
	{
		return add( other );
	}
	Vector!S subtract( const Vector!S other ) pure @safe
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] = values[ ii ] - other.values[ ii ];

		return result;
	}

	Vector!S opUnary( string op : "-" )() pure @safe
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] = -values[ ii ];

		return result;
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

		Vector!S cross( Vector!3 other )
		{
			auto result = new Vector!3;

			result.x = ( y * other.z ) - ( z * other.y );
			result.y = ( z * other.x ) - ( x * other.z );
			result.z = ( x * other.y ) - ( y * other.x );

			return result;
		}
	}

	float[ S ] values;

	mixin Signal!( string, string );
}

// Creates a range from start inclusive to end exclusive.
private template staticIota(size_t start, size_t end)
{
    static if(start == end)
		alias TypeTuple!() staticIota;
    else static if(start < end)
		alias TypeTuple!(start, staticIota!(start + 1, end)) staticIota;
    else
		static assert(0, "start cannot be greater then end!");
}
