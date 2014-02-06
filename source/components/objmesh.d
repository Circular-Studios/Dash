module components.objmesh;

import components.mesh;
import graphics.shaders.shader;
import math.vector;

import std.stdio, std.stream, std.format;

class ObjMesh : Mesh
{
public:

	this( string filePath )
	{
		super( filePath );
		
		// Call mesh.d to setup mesh based on .obj data
		//super( outputData, indices );
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
		super.shutdown();
	}
}