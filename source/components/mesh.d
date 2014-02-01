/**
 * Defines the Mesh class, which controls all meshes loaded into the world.
 */
module components.mesh;
import core.properties;
import components.component;
import graphics.graphics, graphics.shaders.shader;
import math.vector;

import derelict.opengl3.gl3;

import std.stdio, std.stream, std.format;

class Mesh : Component
{
public:
	mixin Property!( "uint", "glVertexArray" );
	mixin Property!( "uint", "numVertices" );
	mixin Property!( "uint", "numIndices" );
	mixin BackedProperty!( "uint", "_glIndexBuffer", "glIndexBuffer" );
	mixin BackedProperty!( "uint", "_glVertexBuffer", "glVertexBuffer" );
	enum VertexSize = float.sizeof * 8u;

	this( string filePath )
	{
		super( null );

		Vector!3[] vertices;
		Vector!2[] uvs;
		Vector!3[] normals;

		float[] outputData;

		auto file = new BufferedFile( filePath );

		foreach( ulong index, char[] line; file )
		{
			if( line[ 0..2 ] == "v " )
			{
				float x, y, z;

				formattedRead( line, "v %s %s %s",
							   &x, &y, &z );

				vertices ~= new Vector!3( x, y, z );
			}
			else if( line[ 0..2 ] == "vt" )
			{
				float x, y;

				formattedRead( line, "vt %s %s",
							   &x, &y );

				uvs ~= new Vector!2( x, y );
			}
			else if( line[ 0..2 ] == "vn" )
			{
				float x, y, z;

				formattedRead( line, "vn %s %s %s",
							   &x, &y, &z );

				normals ~= new Vector!3( x, y, z );
			}
			else if( line[ 0..2 ] == "f " )
			{
				uint vertexIndex[ 3 ];
				uint uvIndex[ 3 ];
				uint normalIndex[ 3 ];

				formattedRead( line, "f %s/%s/%s %s/%s/%s %s/%s/%s",
							   &vertexIndex[ 0 ], &uvIndex[ 0 ], &normalIndex[ 0 ],
							   &vertexIndex[ 1 ], &uvIndex[ 1 ], &normalIndex[ 1 ],
							   &vertexIndex[ 2 ], &uvIndex[ 2 ], &normalIndex[ 2 ] );

				for( uint ii = 0; ii < 3; ++ii )
				{
					outputData ~= vertices[ vertexIndex[ ii ] - 1 ].x;
					outputData ~= vertices[ vertexIndex[ ii ] - 1 ].y;
					outputData ~= vertices[ vertexIndex[ ii ] - 1 ].z;
					outputData ~= uvs[ uvIndex[ ii ] - 1 ].x;
					outputData ~= uvs[ uvIndex[ ii ] - 1 ].y;
					outputData ~= normals[ normalIndex[ ii ] - 1 ].x;
					outputData ~= normals[ normalIndex[ ii ] - 1 ].y;
					outputData ~= normals[ normalIndex[ ii ] - 1 ].z;

				}
			}
		}

		file.close();

		_numVertices = cast(uint)( outputData.length / 8 );  // 8 is num floats per vertex
		_numIndices = numVertices;

		uint[] indices = new uint[ numIndices ];

		foreach( ii; 0..numIndices )
			indices[ ii ] = ii;

		// make and bind the VAO
		glGenVertexArrays( 1, &_glVertexArray );
		glBindVertexArray( glVertexArray );

		// make and bind the VBO
		glGenBuffers( 1, &_glVertexBuffer );
		glBindBuffer( GL_ARRAY_BUFFER, glVertexBuffer );

		// Buffer the data
		glBufferData( GL_ARRAY_BUFFER, outputData.length * GLfloat.sizeof, outputData.ptr, GL_STATIC_DRAW );

		uint POSITION_ATTRIBUTE = 0;
		uint UV_ATTRIBUTE = 1;
		uint NORMAL_ATTRIBUTE = 2;

		// Connect the position to the inputPosition attribute of the vertex shader
		glEnableVertexAttribArray( POSITION_ATTRIBUTE );
		glVertexAttribPointer( POSITION_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(const(void)*)0 );
		// Connect uv to the textureCoordinate attribute of the vertex shader
		glEnableVertexAttribArray( UV_ATTRIBUTE );
		glVertexAttribPointer( UV_ATTRIBUTE, 2, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(char*)0 + ( GLfloat.sizeof * 3 ) );
		// Connect color to the shaderPosition attribute of the vertex shader
		glEnableVertexAttribArray( NORMAL_ATTRIBUTE );
		glVertexAttribPointer( NORMAL_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(char*)0 + ( GLfloat.sizeof * 5 ) );

		// Generate index buffer
		glGenBuffers( 1, &_glIndexBuffer );
		glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, glIndexBuffer );

		// Buffer index data
		glBufferData( GL_ELEMENT_ARRAY_BUFFER, uint.sizeof * numVertices, indices.ptr, GL_STATIC_DRAW );

		// unbind the VBO and VAO
		glBindBuffer( GL_ARRAY_BUFFER, 0 );
		glBindVertexArray( 0 );
	}

	Vector!3[2] calculateTangentBinormal( Vector!3[3] vertices, Vector!2[3] uvs )
	{
		Vector!3[2] tangentBinormal;

		float den;
		float length;

		//Calculate vectors for this face
		vector1.x = v2->xyz.x - v1->xyz.x;
		vector1.y = v2->xyz.y - v1->xyz.y;
		vector1.z = v2->xyz.z - v1->xyz.z;

		vector2.x = v3->xyz.x - v1->xyz.x;
		vector2.y = v3->xyz.y - v1->xyz.y;
		vector2.z = v3->xyz.z - v1->xyz.z;

		//Calculate the UV space vectors
		uvector.x = v2->uv.x - v1->uv.x;
		vvector.x = v2->uv.y - v1->uv.y;

		uvector.y = v3->uv.x - v1->uv.x;
		vvector.y = v3->uv.y - v1->uv.y;

		//Calculate the denominator of the tangent/binormal equation
		den = 1.0f/(uvector.x * vvector.y - uvector.y * vvector.x);

		//Calculate the cross products and multiply by the coefficient to get the tangent and binomial
		tangent.x = (vvector.y * vector1.x - vvector.x * vector2.x) * den;
		tangent.y = (vvector.y * vector1.y - vvector.x * vector2.y) * den;
		tangent.z = (vvector.y * vector1.z - vvector.x * vector2.z) * den;

		binormal.x = (uvector.x * vector2.x - uvector.y * vector1.x) * den;
		binormal.y = (uvector.x * vector2.y - uvector.y * vector1.y) * den;
		binormal.z = (uvector.x * vector2.z - uvector.y * vector1.z) * den;

		//Normalize each vector
		length = sqrt((tangent.x * tangent.x) + (tangent.y * tangent.y) + (tangent.z * tangent.z));
		tangent.x = tangent.x / length;
		tangent.y = tangent.y / length;
		tangent.z = tangent.z / length;

		length = sqrt((binormal.x * binormal.x) + (binormal.y * binormal.y) + (binormal.z * binormal.z));
		binormal.x = binormal.x / length;
		binormal.y = binormal.y / length;
		binormal.z = binormal.z / length;

		return tangentBinormal;
	}

	override void update()
	{

	}

	override void draw( Shader shader )
	{
		//shader.drawMesh( this );
	}

	override void shutdown()
	{
		glDeleteBuffers( 1, &_glVertexBuffer );
		glDeleteBuffers( 1, &_glVertexArray );
	}

private:
	union
	{
		uint _glIndexBuffer;
	}

	union
	{
		uint _glVertexBuffer;
	}
}
