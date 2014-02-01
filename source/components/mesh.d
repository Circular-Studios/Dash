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
	mixin Property!( "uint", "glVertexArray", "protected" );
	mixin Property!( "uint", "numVertices", "protected" );
	mixin Property!( "uint", "numIndices", "protected" );
	mixin BackedProperty!( "uint", "_glIndexBuffer", "glIndexBuffer" );
	mixin BackedProperty!( "uint", "_glVertexBuffer", "glVertexBuffer" );
	enum VertexSize = float.sizeof * 8u;

	this( string filePath )
	{
		super( null );
	}

	this( float[] outputData, uint[] indices )
	{
		super( null );

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

	override void update()
	{

	}

	override void draw( Shader shader )
	{
		// Shouldnt draw if mesh does not have a type
		//shader.drawMesh( this );
	}

	override void shutdown()
	{
		glDeleteBuffers( 1, &_glVertexBuffer );
		glDeleteBuffers( 1, &_glVertexArray );
	}

protected:
	union
	{
		uint _glIndexBuffer;
	}

	union
	{
		uint _glVertexBuffer;
	}
}
