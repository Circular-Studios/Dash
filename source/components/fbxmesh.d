module components.fbxmesh;

import components.mesh;
import graphics.shaders.shader;
import math.vector;

import std.stdio, std.stream, std.format;

class FbxMesh : Mesh
{
public:

	this( string filePath )
	{
		// Read in .fbx data
		

		// Call mesh.d to setup mesh based on .obj data
		super( null );
	}

	override void update()
	{

	}

	override void draw( Shader shader )
	{
		shader.drawMesh( this );
	}

	override void shutdown()
	{
		super.shutdown();
	}
}