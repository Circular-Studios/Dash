/**
 * Defines the Mesh class, which controls all meshes loaded into the world.
 */
module components.mesh;

import core.properties;
import components.component;
import graphics.graphics, graphics.shaders.shader;
import utility.output;
import math.vector;

import derelict.opengl3.gl3;

import std.stdio, std.stream, std.format, std.math;

class Mesh : Component
{
public:
	mixin Property!( "uint", "glVertexArray" );
	mixin Property!( "uint", "numVertices" );
	mixin Property!( "uint", "numIndices" );
	mixin BackedProperty!( "uint", "_glIndexBuffer", "glIndexBuffer" );
	mixin BackedProperty!( "uint", "_glVertexBuffer", "glVertexBuffer" );
	enum VertexSize = float.sizeof * 12u;

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
			if( !line.length )
				continue;

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
				uint[ 3 ] vertexIndex;
				uint[ 3 ] uvIndex;
				uint[ 3 ] normalIndex;

				formattedRead( line, "f %s/%s/%s %s/%s/%s %s/%s/%s",
							   &vertexIndex[ 0 ], &uvIndex[ 0 ], &normalIndex[ 0 ],
							   &vertexIndex[ 1 ], &uvIndex[ 1 ], &normalIndex[ 1 ],
							   &vertexIndex[ 2 ], &uvIndex[ 2 ], &normalIndex[ 2 ] );

				Vector!3[ 3 ] faceVerts = [ vertices[ vertexIndex[ 0 ] - 1 ], vertices[ vertexIndex[ 1 ] - 1 ], vertices[ vertexIndex[ 2 ] - 1 ] ];
				Vector!2[ 3 ] faceUVs = [ uvs[ vertexIndex[ 0 ] - 1 ], uvs[ vertexIndex[ 0 ] - 1 ], uvs[ vertexIndex[ 0 ] - 1 ] ];
				Vector!3[ 2 ] tangentBinormals = calculateTangentBinormal( faceVerts, faceUVs );

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
					
					//Orthogonalize the tangent against the normal, by doing ( t - n * dot(n, t) )
					Vector!3 tangentOrth = ( tangentBinormals[ 0 ] - ( normals[ normalIndex[ ii ] - 1 ] * ( normals[ normalIndex[ ii ] - 1 ] * tangentBinormals[0] ) ) );
					float determinant = ( ( normals[ normalIndex[ ii ] - 1 ] % tangentBinormals[ 0 ] ) * tangentBinormals[ 1 ] );
					if( determinant < 0.0f )
					{
						determinant = -1.0f;
					}
					else
					{
						determinant = 1.0f;
					}

					outputData ~= tangentOrth.x;
					outputData ~= tangentOrth.y;
					outputData ~= tangentOrth.z;
					outputData ~= determinant;
				}
			}
		}

		file.close();

		_numVertices = cast(uint)( outputData.length / 12 );  // 12 is num floats per vertex
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
		uint TANGENT_ATTRIBUTE = 3;

		// Connect the position to the inputPosition attribute of the vertex shader
		glEnableVertexAttribArray( POSITION_ATTRIBUTE );
		glVertexAttribPointer( POSITION_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, VertexSize, cast(const(void)*)0 );
		// Connect uv to the textureCoordinate attribute of the vertex shader
		glEnableVertexAttribArray( UV_ATTRIBUTE );
		glVertexAttribPointer( UV_ATTRIBUTE, 2, GL_FLOAT, GL_FALSE, VertexSize, cast(char*)0 + ( GLfloat.sizeof * 3 ) );
		// Connect normals to the shaderPosition attribute of the vertex shader
		glEnableVertexAttribArray( NORMAL_ATTRIBUTE );
		glVertexAttribPointer( NORMAL_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, VertexSize, cast(char*)0 + ( GLfloat.sizeof * 5 ) );
		// Connect the tangent to the vertex shader
		glEnableVertexAttribArray( TANGENT_ATTRIBUTE );
		glVertexAttribPointer( TANGENT_ATTRIBUTE, 4, GL_FLOAT, GL_FALSE, VertexSize, cast(char*)0 + ( GLfloat.sizeof * 8 ) );

		// Generate index buffer
		glGenBuffers( 1, &_glIndexBuffer );
		glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, glIndexBuffer );

		// Buffer index data
		glBufferData( GL_ELEMENT_ARRAY_BUFFER, uint.sizeof * numVertices, indices.ptr, GL_STATIC_DRAW );

		// unbind the VBO and VAO
		glBindBuffer( GL_ARRAY_BUFFER, 0 );
		glBindVertexArray( 0 );
	}

	/// Calculates two magic numbers (tangent and binormal) which are necessary for normal mapping
	Vector!3[2] calculateTangentBinormal( Vector!3[3] vertices, Vector!2[3] uvs )
	{
		Vector!3[2] tangentBinormal;

		Vector!3 vector1, vector2, tangent, binormal;
		Vector!2 uvector, vvector;
		float den, length;

		//Calculate vectors for this face
		vector1 = new Vector!3( vertices[1].x - vertices[0].x, 
								vertices[1].y - vertices[0].y,
								vertices[1].z - vertices[0].z );

		vector2 = new Vector!3( vertices[2].x - vertices[0].x,
								vertices[2].y - vertices[0].y,
								vertices[2].z - vertices[0].z );

		//Calculate the UV space vectors
		uvector = new Vector!2();
		vvector = new Vector!2();

		uvector.x = uvs[1].x - uvs[0].x;
		vvector.x = uvs[1].y - uvs[0].y;

		uvector.y = uvs[2].x - uvs[0].x;
		vvector.y = uvs[2].y - uvs[0].y;

		//Calculate the denominator of the tangent/binormal equation
		den = 1.0f/(uvector.x * vvector.y - uvector.y * vvector.x);

		//Calculate the cross products and multiply by the coefficient to get the tangent and binomial
		tangent = new Vector!3();
		tangent.x = (vvector.y * vector1.x - vvector.x * vector2.x) * den;
		tangent.y = (vvector.y * vector1.y - vvector.x * vector2.y) * den;
		tangent.z = (vvector.y * vector1.z - vvector.x * vector2.z) * den;
		
		binormal = new Vector!3();
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

		//Store them in the vertices
		tangentBinormal[0] = tangent;
		tangentBinormal[1] = binormal;

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
