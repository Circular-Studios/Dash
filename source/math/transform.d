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
		scale = new Vector!3( 1.0, 1.0, 1.0);

		position.connect( &emit );
		rotation.connect( &emit );
		scale.connect( &emit );

		updateMatrix();

		connect( &setMatrixDirty );
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

	mixin EmmittingProperty!( "Vector!3", "position", "public" );
	mixin EmmittingProperty!( "Quaternion", "rotation", "public" );
	mixin EmmittingProperty!( "Vector!3", "scale", "public" );
	mixin DirtyProperty!( "Matrix!4", "matrix", "updateMatrix" );

	mixin Signal!( string, string );

private:
	void setMatrixDirty( string prop, string newVal )
	{
		_matrixIsDirty = true;
	}

	void updateMatrix()
	{
		auto newMatrix = new Matrix!4;

		// Scale
		newMatrix.matrix[ 0 ][ 0 ] = scale.x;
		newMatrix.matrix[ 1 ][ 1 ] = scale.y;
		newMatrix.matrix[ 2 ][ 2 ] = scale.z;
		newMatrix.matrix[ 3 ][ 3 ] = 1.0f;

		// Rotate
		_matrix = newMatrix * rotation.matrix;

		// Translate
		_matrix.matrix[ 3 ][ 0 ] = position.x;
		_matrix.matrix[ 3 ][ 1 ] = position.y;
		_matrix.matrix[ 3 ][ 2 ] = position.z;
	}
}
