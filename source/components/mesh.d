/**
 * Defines the Mesh class, which controls all meshes loaded into the world.
 */
module components.mesh;
import core, components, graphics, utility;

import derelict.opengl3.gl3, derelict.assimp3.assimp;
import gl3n.linalg;

import std.stdio, std.stream, std.format, std.math;

/**
 * Loads and manages meshes into OpenGL.
 * 
 * Supported formats:
 *  3DS
 *  BLEND (Blender 3D)
 *  DAE/Collada
 *  FBX
 *  IFC-STEP
 *  ASE
 *  DXF
 *  HMP
 *  MD2
 *  MD3
 *  MD5
 *  MDC
 *  MDL
 *  NFF
 *  PLY
 *  STL
 *  X
 *  OBJ
 *  SMD
 *  LWO
 *  LXO
 *  LWS
 *  TER
 *  AC3D
 *  MS3D
 *  COB
 *  Q3BSP
 *  XGL
 *  CSM
 *  BVH
 *  B3D
 *  NDO
 *  Ogre XML
 *  Q3D
 */
shared class Mesh : IComponent
{
private:
    uint _glVertexArray, _numVertices, _numIndices, _glIndexBuffer, _glVertexBuffer;
    bool _animated;

public:
    /// TODO
    mixin( Property!_glVertexArray );
    /// TODO
    mixin( Property!_numVertices );
    /// TODO
    mixin( Property!_numIndices );
    /// TODO
    mixin( Property!_glIndexBuffer );
    /// TODO
    mixin( Property!_glVertexBuffer );
    /// TODO
    mixin( Property!_animated );

    /**
     * Creates a mesh.
     * 
     * Params:
     *      filePath =          The path to the file.
     *      mesh =              The AssImp mesh object to pull data from.
     */
    this( string filePath, const(aiMesh*) mesh )
    {
        int floatsPerVertex, vertexSize;
        float[] outputData;
        uint[] indices;
        animated = false;
        if( mesh )
        {
            // If there is animation data
            if( mesh.mNumBones > 0 )
            {
                // (8 floats for animation data)
                animated = true;
                floatsPerVertex = 19;
                vertexSize = cast(int)(float.sizeof * floatsPerVertex);
                
                // Get the vertex anim data
                float[][] vertBones = new float[][ mesh.mNumVertices ];
                float[][] vertWeights = new float[][ mesh.mNumVertices ];
                for( int bone = 0; bone < mesh.mNumBones; bone++ )
                {       
                    const(aiBone*) tempBone = mesh.mBones[ bone ];
                    for( int weight = 0; weight < mesh.mBones[ bone ].mNumWeights; weight++ )
                    {
                        vertBones[ cast(int)mesh.mBones[ bone ].mWeights[ weight ].mVertexId ] ~= bone;
                        vertWeights[ cast(int)mesh.mBones[ bone ].mWeights[ weight ].mVertexId ] ~= mesh.mBones[ bone ].mWeights[ weight ].mWeight;
                    }
                }

                // Make sure each is 4, if not bring or truncate to 4
                int maxBonesAttached = 0;
                for( int i = 0; i < mesh.mNumVertices; i++)
                {
                    if ( vertBones[i].length > maxBonesAttached )
                        maxBonesAttached = cast(int)vertBones[i].length;

                    while(vertBones[i].length < 4)
                    {
                        vertBones[i] ~= 0;
                    }

                    while(vertWeights[i].length < 4)
                    {
                        vertWeights[i] ~= 0.0f;
                    }

                }
                if( maxBonesAttached > 4 )
                {
                    log( LoggingLevel.Warning, filePath, " has more than 4 bones for some vertex, data will be truncated. (has ", maxBonesAttached, ")" );
                }

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
                        float w = calcTangentHandedness(normal, tangent, bitangent);

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
                        outputData ~= vertBones[ face.mIndices[ j ] ][0..4];
                        outputData ~= vertWeights[ face.mIndices[ j ] ][0..4];
                    }
                }
            }
            // Otherwise render without animation
            if( mesh.mNumBones == 0 || animated == false ) // No animation or animation failed
            {
                animated = false;
                floatsPerVertex = 11;
                vertexSize = cast(int)(float.sizeof * floatsPerVertex);

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
                        float w = calcTangentHandedness(normal, tangent, bitangent);

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
            }

            numVertices = cast(uint)( outputData.length / floatsPerVertex );
            numIndices = numVertices;

            indices = new uint[ numIndices ];
            foreach( ii; 0..numIndices )
                indices[ ii ] = ii;
        }
        else
        {
            // Did not load
            log( LoggingLevel.Fatal, "Mesh not loaded: ", filePath );
        }
        
        // make and bind the VAO
        glGenVertexArrays( 1, cast(uint*)&_glVertexArray );
        glBindVertexArray( glVertexArray );

        // make and bind the VBO
        glGenBuffers( 1, cast(uint*)&_glVertexBuffer );
        glBindBuffer( GL_ARRAY_BUFFER, glVertexBuffer );

        // Buffer the data
        glBufferData( GL_ARRAY_BUFFER, outputData.length * GLfloat.sizeof, outputData.ptr, GL_STATIC_DRAW );

        uint POSITION_ATTRIBUTE = 0;
        uint UV_ATTRIBUTE = 1;
        uint NORMAL_ATTRIBUTE = 2;
        uint TANGENT_ATTRIBUTE = 3;
        //uint BINORMAL_ATTRIBUTE = 4;

        // Connect the position to the inputPosition attribute of the vertex shader
        glEnableVertexAttribArray( POSITION_ATTRIBUTE );
        glVertexAttribPointer( POSITION_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, vertexSize, cast(const(void)*)0 );
        // Connect uv to the textureCoordinate attribute of the vertex shader
        glEnableVertexAttribArray( UV_ATTRIBUTE );
        glVertexAttribPointer( UV_ATTRIBUTE, 2, GL_FLOAT, GL_FALSE, vertexSize, cast(char*)0 + ( GLfloat.sizeof * 3 ) );
        // Connect normals to the shaderPosition attribute of the vertex shader
        glEnableVertexAttribArray( NORMAL_ATTRIBUTE );
        glVertexAttribPointer( NORMAL_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, vertexSize, cast(char*)0 + ( GLfloat.sizeof * 5 ) );
        // Connect the tangent to the vertex shader
        glEnableVertexAttribArray( TANGENT_ATTRIBUTE );
        glVertexAttribPointer( TANGENT_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, vertexSize, cast(char*)0 + ( GLfloat.sizeof * 8 ) );
        // Connect the binormal to the vertex shader (Remember to change animation data values properly!!!)
        //glEnableVertexAttribArray( BINORMAL_ATTRIBUTE );
        //glVertexAttribPointer( BINORMAL_ATTRIBUTE, 3, GL_FLOAT, GL_FALSE, vertexSize, cast(char*)0 + ( GLfloat.sizeof * 11 ) );

        if( animated )
        {
            uint BONE_ATTRIBUTE = 4;
            uint WEIGHT_ATTRIBUTE = 5;

            glEnableVertexAttribArray( BONE_ATTRIBUTE );
            glVertexAttribPointer( BONE_ATTRIBUTE, 4, GL_FLOAT, GL_FALSE, vertexSize, cast(char*)0 + ( GLfloat.sizeof * 11 ) );
            glEnableVertexAttribArray( WEIGHT_ATTRIBUTE );
            glVertexAttribPointer( WEIGHT_ATTRIBUTE, 4, GL_FLOAT, GL_FALSE, vertexSize, cast(char*)0 + ( GLfloat.sizeof * 15 ) );
        }

        // Generate index buffer
        glGenBuffers( 1, cast(uint*)&_glIndexBuffer );
        glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, glIndexBuffer );

        // Buffer index data
        glBufferData( GL_ELEMENT_ARRAY_BUFFER, uint.sizeof * numVertices, indices.ptr, GL_STATIC_DRAW );

        // unbind the VBO and VAO
        glBindVertexArray( 0 );
    }

    override void update() { }

    /**
     * Deletes mesh data stored on the GPU.
     */
    override void shutdown()
    {
        glDeleteBuffers( 1, cast(uint*)&_glVertexBuffer );
        glDeleteBuffers( 1, cast(uint*)&_glVertexArray );
    }
}


/**
 * Helper function that calculates a modifier for the reconstructed bitangent based on regenerating them
 * May be needed elsewhere
 *
 * Params: TODO
 *
 * Returns:
 */
private float calcTangentHandedness( aiVector3D nor, aiVector3D tan, aiVector3D bit )
{
    shared vec3 n = vec3( nor.x, nor.y, nor.z );
    shared vec3 t = vec3( tan.x, tan.y, tan.z );
    shared vec3 b = vec3( bit.x, bit.y, bit.z );

    //Gramm-schmidt
    t = (t - n * dot( n, t )).normalized();

    return (dot(cross(n,t),b) > 0.0f) ? -1.0f : 1.0f;
}

static this()
{
    import yaml;
    IComponent.initializers[ "Mesh" ] = ( Node yml, shared GameObject obj )
    {
        obj.mesh = Assets.get!Mesh( yml.get!string );
        
        // If the mesh has animation also add animation component
        if( obj.mesh.animated )
        {
            auto anim = new shared Animation( Assets.get!AssetAnimation( yml.get!string ) );
            obj.addComponent( anim );
            obj.animation = anim;
        }

        return obj.mesh;
    };
}
