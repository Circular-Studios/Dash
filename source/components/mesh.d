/**
 * Defines the Mesh class, which controls all meshes loaded into the world.
 */
module components.mesh;

import core.properties;
import components.component;
import graphics.graphics, graphics.shaders;
import utility.output;

import derelict.assimp3.assimp;
import derelict.opengl3.gl3;

import std.stdio, std.stream, std.format, std.math;

class Mesh : Component
{
public:
	mixin Property!( "uint", "glVertexArray", "protected" );
	mixin Property!( "uint", "numVertices", "protected" );
	mixin Property!( "uint", "numIndices", "protected" );
	mixin BackedProperty!( "uint", "_glIndexBuffer", "glIndexBuffer" );
	mixin BackedProperty!( "uint", "_glVertexBuffer", "glVertexBuffer" );
	enum FloatsPerVertex = 11;
	enum VertexSize = float.sizeof * FloatsPerVertex;

	this( string filePath )
	{
		super( null );

		// Initial assimp start
		DerelictASSIMP3.load();

		// Load the scene via assimp
		const aiScene* scene = aiImportFile(( filePath ~ "\0" ).ptr,
											aiProcess_CalcTangentSpace | aiProcess_Triangulate | 
											aiProcess_JoinIdenticalVertices | aiProcess_SortByPType |
											aiProcess_MakeLeftHanded | aiProcess_FlipWindingOrder );
		float[] outputData;
		uint[] indices;
		if(!scene)
		{
			// Did not load
			log( OutputType.Error, "Mesh not loaded: ", filePath );
		}
		else
		{
			// Get the mesh
			auto mesh = scene.mMeshes[0];

			// For each vertex on each face
 			int meshFaces = mesh.mNumFaces;
			for( int i = 0; i < meshFaces; i++ )
			{
				auto face = mesh.mFaces[i];
				for( int j = 0; j < 3; j++ )
				{
					// Get the vertex data
					aiVector3D pos = mesh.mVertices[ face.mIndices[ j ] ];
					aiVector3D uv = mesh.mTextureCoords[ 0 ][ face.mIndices[ j ] ];
					aiVector3D normal = mesh.mNormals[ face.mIndices[ j ] ];
					aiVector3D tangent = mesh.mTangents[ face.mIndices[ j ] ];
					aiVector3D bitangent = mesh.mBitangents[ face.mIndices[ j ] ];

					// Append the data
					outputData ~= pos.x;
					outputData ~= pos.y;
					outputData ~= pos.z;
					outputData ~= uv.x;
					outputData ~= uv.y;
					outputData ~= normal.x;
					outputData ~= normal.y;
					outputData ~= normal.z;
					outputData ~= tangent.x;
					outputData ~= tangent.y;
					outputData ~= tangent.z;
					//outputData ~= bitangent.x;
					//outputData ~= bitangent.y;
					//outputData ~= bitangent.z;
				}
			}

			numVertices = cast(uint)( outputData.length / FloatsPerVertex );  // 11 is num floats per vertex
			numIndices = numVertices;

			indices = new uint[ numIndices ];
			foreach( ii; 0..numIndices )
				indices[ ii ] = ii;
		}
		// Release assimp instance now that we have all the model data
		aiReleaseImport( scene );

		
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
		uint BINORMAL_ATTRIBUTE = 4;

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
		glVertexAttribPointer( TANGENT_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, VertexSize, cast(char*)0 + ( GLfloat.sizeof * 8 ) );
		// Connect the binormal to the vertex shader
		//glEnableVertexAttribArray( BINORMAL_ATTRIBUTE );
		//glVertexAttribPointer( BINORMAL_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, VertexSize, cast(char*)0 + ( GLfloat.sizeof * 11 ) );

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
