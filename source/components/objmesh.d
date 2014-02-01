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
		// Read in .obj data
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

		numVertices = cast(uint)( outputData.length / 8 );  // 8 is num floats per vertex
		numIndices = numVertices;

		uint[] indices = new uint[ numIndices ];

		foreach( ii; 0..numIndices )
			indices[ ii ] = ii;
		
		// Call mesh.d to setup mesh based on .obj data
		super( outputData, indices );
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