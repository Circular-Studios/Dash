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