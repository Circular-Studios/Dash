module dash.utility.math;

version( DashUseGl3n )
{
public:
    // Linear Algebra types
    import gl3n.linalg;

    // Vectors
    alias vec2f = Vector!( float, 2 );
    alias vec2ui = Vector!( uint, 2 );
    alias vec3f = Vector!( float, 3 );
    alias vec4f = Vector!( float, 4 );

    // Quaternions
    alias quatf = Quaternion!float;

    inout(Matrix!( Floating, Size, Size )) toMatrix( uint Size, Floating )( inout Quaternion!Floating q ) @property
        if( Size == 3 || Size == 4 )
    {
        return q.to_matrix!( Size, Size );
    }

    inout(Vector!( Floating, 3 )) toEulerAngles( Floating )( inout Quaternion!Floating q ) @property
    {
        return typeof(return)( q.pitch, q.yaw, q.roll );
    }

    Quaternion!Floating fromEulerAngles( Floating = float )( Floating pitch, Floating yaw, Floating roll )
    {
        return Quaternion!Floating.identity.rotatex( pitch.radians ).rotatey( yaw.radians ).rotatez( roll.radians );
    }

    Quaternion!Floating fromEulerAngles( Floating = float )( Vector!( Floating, 3 ) vec )
    {
        return fromEulerAngles( vec.x, vec.y, vec.z );
    }

    Quaternion!Floating fromEulerAngles( Floating = float )( Floating[] angles )
    in
    {
        assert( angles.length >= 3, "Invalid array given." );
    }
    body
    {
        return fromEulerAngles( angles[ 0 ], angles[ 1 ], angles[ 2 ] );
    }

    // Matrices
    alias mat4f = Matrix!( float, 4, 4 );

    mat4f perspectiveMat( float width, float height, float fov, float near, float far )
    {
        return mat4f.perspective( width, height, fov, near, far );
    }

    // Interpolation functions
    import gl3n.interpolate;

    // AABB types
    import gl3n.aabb;
    alias box3f = AABBT!float;

    void expandInPlace( Floating )( ref AABBT!Floating box, Vector!( Floating, 3 ) v )
    {
        box.expand( v );
    }

    // Other functions
    import gl3n.frustum;
    import gl3n.math;
}
else version( DashUseGfmMath )
{

}