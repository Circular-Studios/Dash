module math.vector;

class Vector( uint S = 3 )
{
public:
	this( float def = 0.0f )
	{
		for( uint ii = 0; ii < S; ++ii )
			values[ ii ] = def;
	}

	this( float[] arg ... )
	{
		static assert( arg.length == S, "Invalid number of arguments" );

		for( uint ii = 0; ii < S; ++ii )
			values[ ii ] = arg[ ii ];
	}

	/**
		Calls other operators, and assigns results back to itself
	*/
	Vector!S opOpAssign( string op )( const Vector!S other )
	{
		values = opBinary!( op[ 0 ] )( other ).values;
		return this;
	}

	float dot( const Vector!S other ) pure
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

	Vector!S opBinary( string op : "*" )( const float other ) pure
	{
		return mulitdlply( other );
	}
	Vector!S multiply( const Vector!S other ) pure
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] += values[ ii ] * other;

		return result;
	}

	Vector!S opBinary( string op : "+" )( const Vector!S other ) pure
	{
		return add( other );
	}
	Vector!S add( const Vector!S other ) pure
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] = values[ ii ] + other.values[ ii ];

		return result;
	}

	Vector!S opBinary( string op : "-" )( const Vector!S other ) pure
	{
		return add( other );
	}
	Vector!S subtract( const Vector!S other ) pure
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] = values[ ii ] - other.values[ ii ];

		return result;
	}

	Vector!S opUnary( string op : "-" )() pure
	{
		auto result = new Vector!S;

		for( uint ii = 0; ii < S; ++ii )
			result.values[ ii ] = -values[ ii ];

		return result;
	}

private:
	float[ S ] values;
}

class Vector( uint S : 2 )
{
public:
	static const Vector!3 up = new Vector!3( 0.0f, 1.0f );
	static const Vector!3 right = new Vector!3( 1.0f, 0.0f );

	alias values[ 0 ] x;
	alias values[ 1 ] y;
}

class Vector( uint S : 3 )
{
public:
	static const Vector!3 up = new Vector!3( 0.0f, 1.0f, 0.0f );
	static const Vector!3 forward = new Vector!3( 0.0f, 0.0f, 1.0f );
	static const Vector!3 right = new Vector!3( 1.0f, 0.0f, 0.0f );

	alias values[ 0 ] x;
	alias values[ 1 ] y;
	alias values[ 2 ] z;

	Vector!S cross( const Vector!3 other ) pure
	{
		auto result = new Vector!3;

		result.x = ( y * other.z ) - ( z * other.y );
		result.y = ( z * other.x ) - ( x * other.z );
		result.z = ( x * other.y ) - ( y * other.x );

		return result;
	}
}

class Vector( uint S : 4 )
{
public:
	alias values[ 0 ] x;
	alias values[ 1 ] y;
	alias values[ 2 ] z;
	alias values[ 3 ] w;
}