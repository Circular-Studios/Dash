/**
 * Defines the Mesh class, which controls all meshes loaded into the world.
 */
module components.mesh;
import core.properties;
import components.icomponent;
import graphics.graphics, graphics.shaders.ishader;
import math.vector;

import derelict.opengl3.gl3;

import std.stdio, std.stream;

class Mesh : IComponent
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

		Stream file = new BufferedFile( filePath );

		foreach( ulong index, char[] line; file )
		{
			if( line[ 0..2 ] == "v " )
			{
				float x, y, z;

				sscanf( line.ptr, "v %f %f %f\n", &x, &y, &z );

				vertices ~= new Vector!3( x, y, z );
			}
			else if( line[ 0..2 ] == "vt" )
			{
				float x, y;

				sscanf( line.ptr, "vt %f %f\n", &x, &y );

				uvs ~= new Vector!2( x, y );
			}
			else if( line[ 0..2 ] == "vn" )
			{
				float x, y, z;

				sscanf( line.ptr, "vn %f %f %f\n", &x, &y, &z );

				normals ~= new Vector!3( x, y, z );
			}
			else if( line[ 0..2 ] == "f " )
			{
				uint vertexIndex[ 3 ];
				uint uvIndex[ 3 ];
				uint normalIndex[ 3 ];

				sscanf( line.ptr, "f %d/%d/%d %d/%d/%d %d/%d/%d\n",
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

		for( uint ii = 0; ii < indices.length; ++ii )
			indices[ ii ] = ii;

		if( Graphics.activeAdapter == GraphicsAdapter.OpenGL )
		{
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
		version( Windows )
		if( Graphics.activeAdapter == GraphicsAdapter.DirectX )
		{

		}
	}

	override void update()
	{

	}

	override void draw( IShader shader )
	{
		shader.drawMesh( this );
	}

	override void shutdown()
	{
		if( Graphics.activeAdapter == GraphicsAdapter.OpenGL )
		{
			glDeleteBuffers( 1, &_glVertexBuffer );
			glDeleteBuffers( 1, &_glVertexArray );
		}
		version( Windows )
		if( Graphics.activeAdapter == GraphicsAdapter.DirectX )
		{
			
		}
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
