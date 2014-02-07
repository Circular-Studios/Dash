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
					outputData ~= tangentBinormals[ 0 ].x;
					outputData ~= tangentBinormals[ 0 ].y;
					outputData ~= tangentBinormals[ 0 ].z;
					outputData ~= tangentBinormals[ 1 ].x;
					outputData ~= tangentBinormals[ 1 ].y;
					outputData ~= tangentBinormals[ 1 ].z;
				}
			}
		}

		file.close();

		numVertices = cast(uint)( outputData.length / 14 );  // 14 is num floats per vertex
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
		//shader.drawMesh( this );
	}

	override void shutdown()
	{
		super.shutdown();
	}
}