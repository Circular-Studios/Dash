/**
 * Defines the Mesh class, which controls all meshes loaded into the world.
 */
module dash.components.mesh;
import dash.core, dash.components, dash.graphics, dash.utility;

import derelict.opengl3.gl3, derelict.assimp3.assimp;
import std.stdio, std.stream, std.format, std.math, std.string;

mixin( registerComponents!() );

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
class MeshAsset : Asset
{
private:
    uint _glVertexArray, _numVertices, _numIndices, _glIndexBuffer, _glVertexBuffer;
    bool _animated;
    box3f _boundingBox;
    AnimationData _animationData;

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
    /// Stores all data about animations on the mesh.
    mixin( Property!( _animationData, AccessModifier.Package ) );
    /// The bounding box of the mesh.
    mixin( RefGetter!_boundingBox );

    /**
     * Creates a mesh.
     *
     * Params:
     *      filePath =          The path to the file.
     *      mesh =              The AssImp mesh object to pull data from.
     */
    this( Resource filePath, const(aiMesh*) mesh )
    {
        super( filePath );
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
                    warningf( "%s has more than 4 bones for some vertex, data will be truncated. (has %s)", filePath, maxBonesAttached );
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
                        outputData ~= vertBones[ face.mIndices[ j ] ][0..4];
                        outputData ~= vertWeights[ face.mIndices[ j ] ][0..4];

                        // Save the position in verts
                        boundingBox.expandInPlace( vec3f( pos.x, pos.y, pos.z ) );
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

                        // Save the position in verts
                        boundingBox.expandInPlace( vec3f( pos.x, pos.y, pos.z ) );
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
            fatalf( "Mesh not loaded: %s", filePath );
        }

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

    /**
     * Refresh the asset.
     */
    override void refresh()
    {
        shutdown();

        // Load mesh
        const aiScene* scene = aiImportFile( resource.fullPath.toStringz,
                                             aiProcess_CalcTangentSpace | aiProcess_Triangulate |
                                             aiProcess_JoinIdenticalVertices | aiProcess_SortByPType );
        assert( scene, "Failed to load scene file '" ~ resource.fullPath ~ "' Error: " ~ aiGetErrorString().fromStringz );

        // Add mesh
        if( scene.mNumMeshes > 0 )
        {
            auto tempMesh = new MeshAsset( resource, scene.mMeshes[ 0 ] );

            if( scene.mNumAnimations > 0 )
                tempMesh.animationData = new AnimationData( resource, scene.mAnimations, scene.mNumAnimations, scene.mMeshes[ 0 ], scene.mRootNode );

            // Copy attributes
            _glVertexArray = tempMesh._glVertexArray;
            _numVertices = tempMesh._numVertices;
            _numIndices = tempMesh._numIndices;
            _glIndexBuffer = tempMesh._glIndexBuffer;
            _glVertexBuffer = tempMesh._glVertexBuffer;
            _animated = tempMesh._animated;
            _boundingBox = tempMesh._boundingBox;
        }
        else
        {
            warning( "Assimp did not contain mesh data, ensure you are loading a valid mesh." );
            return;
        }

        // Release mesh
        aiReleaseImport( scene );
    }

    /**
     * Deletes mesh data stored on the GPU.
     */
    override void shutdown()
    {
        glDeleteBuffers( 1, &_glVertexBuffer );
        glDeleteBuffers( 1, &_glVertexArray );
    }
}

class Mesh : AssetRef!MeshAsset
{
    alias asset this;

    this() { }
    this( MeshAsset ass )
    {
        super( ass );
    }

    override void initialize()
    {
        super.initialize();

        if( animated && owner )
            owner.addComponent( animationData.getComponent() );
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
    vec3f n = vec3f( nor.x, nor.y, nor.z );
    vec3f t = vec3f( tan.x, tan.y, tan.z );
    vec3f b = vec3f( bit.x, bit.y, bit.z );

    //Gramm-schmidt
    t = (t - n * dot( n, t )).normalized();

    return (dot(cross(n,t),b) > 0.0f) ? -1.0f : 1.0f;
}
