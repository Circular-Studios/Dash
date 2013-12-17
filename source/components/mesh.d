module components.mesh;
import core.global;
import components.icomponent;
import graphics.graphics;
import graphics.shaders.ishader;

import derelict.opengl3.gl3;

class Mesh : IComponent
{
public:
	mixin( Property!( "uint", "glVertexArray" ) );
	mixin( Property!( "uint", "numVerticies" ) );
	mixin( BackedProperty!( "uint", "_glIndexBuffer", "glIndexBuffer" ) );
	mixin( BackedProperty!( "uint", "_glVertexBuffer", "glVertexBuffer" ) );
	static @property uint vertexSize() { return float.sizeof * 8; }

	this( string filePath )
	{
		super( null );

		if( Graphics.activeAdapter == GraphicsAdapter.OpenGL )
		{
			/*
			// make and bind the VAO
			glGenVertexArrays( 1, &_glVertexArray );
			glBindVertexArray( glVertexArray );

			// make and bind the VBO
			glGenBuffers( 1, &_glVertexBuffer );
			glBindBuffer( GL_ARRAY_BUFFER, glVertexBuffer );

			// Buffer the data
			glBufferData( GL_ARRAY_BUFFER, outputData.size() * GLfloat.sizeof, &outputData[ 0 ], GL_STATIC_DRAW );

			// Connect the position to the inputPosition attribute of the vertex shader
			glEnableVertexAttribArray( POSITION_ATTRIBUTE );
			glVertexAttribPointer( POSITION_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, NULL );
			// Connect uv to the textureCoordinate attribute of the vertex shader
			glEnableVertexAttribArray( UV_ATTRIBUTE );
			glVertexAttribPointer( UV_ATTRIBUTE, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), cast(char*)0 + ( GLfloat.sizeof * 3 ) );
			// Connect color to the shaderPosition attribute of the vertex shader
			glEnableVertexAttribArray( NORMAL_ATTRIBUTE );
			glVertexAttribPointer( NORMAL_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, 8 * GLfloat.sizeof, cast(char*)0 + ( GLfloat.sizeof * 5 ) );

			// Generate index buffer
			glGenBuffers( 1, &_glIndexBuffer );
			glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, glIndexBuffer );

			// Buffer index data
			glBufferData( GL_ELEMENT_ARRAY_BUFFER, uint.sizeof * numVertices, &indices[ 0 ], GL_STATIC_DRAW );

			// unbind the VBO and VAO
			glBindBuffer( GL_ARRAY_BUFFER, 0 );
			glBindVertexArray( NULL );
			*/
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
