/**
 * TODO
 */
module components.animation;
import core.properties;
import components.icomponent;
import utility.output, utility.time;

import derelict.assimp3.assimp;
import gl3n.linalg;

/**
 * TODO
 */
shared class Animation : IComponent
{
private:
    shared AssetAnimation _animationData;
    shared int _currentAnim;
    shared float _currentAnimTime;
    shared mat4[] _currBoneTransforms;
    shared bool _animating;

public:
    /// TODO
    mixin( Property!_animationData );
    /// TODO
    mixin( Property!_currentAnim );
    /// TODO
    mixin( Property!_currentAnimTime );
    /// TODO
    mixin( Property!_currBoneTransforms );

    /**
     * TODO
     */
    this( shared AssetAnimation assetAnimation )
    {
        _currentAnim = 0;
        _currentAnimTime = 0.0f;
        _animationData = assetAnimation;
        _animating = true;
    }

    /**
     * Updates the animation's bones.
     */
    override void update() 
    {
        if( _animating )
        {
            // Update currentanimtime based on changeintime
            _currentAnimTime += 0.02f;

            if( _currentAnimTime > 96.0f )
            {
                _currentAnimTime = 0.0f;
            }

            // Calculate and store array of bonetransforms to pass to the shader
            currBoneTransforms = animationData.getTransformsAtTime( _currentAnimTime );
        }
    }

    /**
     * TODO
     */
    override void shutdown() 
    { 

    }

    /**
     * Stops the animation from updating.
     */
    void pause()
    {
        _animating = false;
    }

    /**
     * Stops the animation from updating and resets it.
     */
    void stop()
    {
        _animating = false;
        _currentAnimTime = 0.0f;
    }

    /**
     * Allows animation to update.
     */
    void play()
    {
        _animating = true;
    }
}

/**
 * TODO
 */
shared class AssetAnimation
{
private:
    shared AnimationSet _animationSet;
    shared int _numberOfBones;

public:
    /// TODO
    mixin( Property!_animationSet );
    /// TODO
    mixin( Property!_numberOfBones );

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    this( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) boneHierarchy )
    {
        _animationSet.duration = cast(float)animation.mDuration;
        _animationSet.fps = cast(float)animation.mTicksPerSecond;

		_animationSet.animBones = makeBonesFromHierarchy( animation, mesh, boneHierarchy, null, "Head" );
    }

    /**
     * 
     *
     * Params: TODO
     *
     * Returns: TODO
     */
    shared(Bone) makeBonesFromHierarchy( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) currNode, shared Bone returnBone, string parentName )
    { 
		// NOTE: Currently only works if each node is a Bone, only works with bones without animation b/c of storing nodeOffset
		// NOTE: Needs to be reworked to support this in the future

        string name = cast(string)currNode.mName.data[ 0 .. currNode.mName.length ];
        int id = findBoneWithName( name, mesh );
        shared Bone bone;

        if( id != -1 && name )
        {
            bone = new shared Bone( name, id );
			
			bone.offset = convertAIMatrix( mesh.mBones[ bone.id ].mOffsetMatrix );
			bone.nodeOffset = convertAIMatrix( currNode.mTransformation );

            assignAnimationData( animation, bone );

            returnBone = bone;
            _numberOfBones++;
        }
        else
        {
            bone = returnBone;
        }

        // For each child node
        for( int i = 0; i < currNode.mNumChildren; i++ )
        {
            // Create it and assign to this node as a child
            if( id != -1 )
                bone.children ~= makeBonesFromHierarchy( animation, mesh, currNode.mChildren[ i ], bone, name );
            else
                return makeBonesFromHierarchy( animation, mesh, currNode.mChildren[ i ], bone, name );
        }

        return bone;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    void assignAnimationData( const(aiAnimation*) animation, shared Bone boneToAssign )
    {
        // For each bone animation data
        for( int i = 0; i < animation.mNumChannels; i++)
        {
            string name = cast(string)animation.mChannels[ i ].mNodeName.data[ 0 .. animation.mChannels[ i ].mNodeName.length ];

			if( name == boneToAssign.name )
            {
                // Assign the bone animation data to the bone
                boneToAssign.positionKeys = convertVectorArray( animation.mChannels[ i ].mPositionKeys,
                                                                animation.mChannels[ i ].mNumPositionKeys );

                boneToAssign.scaleKeys = convertVectorArray( animation.mChannels[ i ].mScalingKeys,
                                                             animation.mChannels[ i ].mNumScalingKeys );

                boneToAssign.rotationKeys = convertQuat( animation.mChannels[ i ].mRotationKeys,
                                                         animation.mChannels[ i ].mNumRotationKeys );
            }
        }
    }

    /**
     * Converts a aiVectorKey[] to vec3[].
     *
     * Params:
     *
     * Returns:
     */ 
    shared( vec3[] ) convertVectorArray( const(aiVectorKey*) vectors, int numKeys )
    {
        shared vec3[] keys;
        for( int i = 0; i < numKeys; i++ )
        {
            aiVector3D vector = vectors[ i ].mValue;
            keys ~= vec3( vector.x, vector.y, vector.z );
        }

        return keys;
    }
    /**
     * Converts a aiQuatKey[] to quat[].
     *
     * Params:
     *
     * Returns:
     */
    shared( quat[] ) convertQuat( const(aiQuatKey*) quaternions, int numKeys )
    {
        shared quat[] keys;
        for( int i = 0; i < numKeys; i++ )
        {
            aiQuatKey quaternion = quaternions[ i ];
            keys ~= quat( quaternion.mValue.w, quaternion.mValue.x, quaternion.mValue.y, quaternion.mValue.z );
            int ii = 0;
        }

        return keys;
    }

    /**
     * Find bone with name in our structure.
     *
     * Params:
     *
     * Returns:
     */
    int findBoneWithName( string name, const(aiMesh*) mesh )
    {
        for( int i = 0; i < mesh.mNumBones; i++ )
        {
            if( name == cast(string)mesh.mBones[ i ].mName.data[ 0 .. mesh.mBones[ i ].mName.length ] )
            {
                return i;
            }
        }

        return -1;
    }
    /**
     * Check if string stringToTest ends with string end
     *
     * Params:
     *
     * Returns:
     */
    bool checkEnd( string stringToTest, string end )
    {
        if( stringToTest.length > end.length )
        {
            string temp = stringToTest[ (stringToTest.length - end.length) .. stringToTest.length ];

            if( stringToTest[ (stringToTest.length - end.length) .. stringToTest.length ] == end )
            {
                return true;
            }
        }

        return false;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    shared( mat4[] ) getTransformsAtTime( shared float time )
    {
        shared mat4[] boneTransforms = new shared mat4[ _numberOfBones ];

        // Check shader/model
        for( int i = 0; i < _numberOfBones; i++)
        {
            boneTransforms[ i ] = mat4.identity;
        }
		
        fillTransforms( boneTransforms, _animationSet.animBones, time, mat4.identity );

        return boneTransforms;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    void fillTransforms( shared mat4[] transforms, shared Bone bone, shared float time, shared mat4 parentTransform )
    {
        // Calculate matrix based on bone data and time
        shared mat4 finalTransform;
        shared mat4 boneTransform = mat4.identity;

		if( bone.positionKeys.length > cast(int)time )
		{
            boneTransform = boneTransform.translation( bone.positionKeys[ cast(int)time ].vector[ 0 ], bone.positionKeys[ cast(int)time ].vector[ 1 ], 
																	   bone.positionKeys[ cast(int)time ].vector[ 2 ] );
		}
		if( bone.rotationKeys.length > cast(int)time )
		{
			boneTransform = boneTransform * bone.rotationKeys[ cast(int)time ].to_matrix!( 4, 4 );
		}
		if( bone.scaleKeys.length > cast(int)time )
		{
            boneTransform = boneTransform.scale( bone.scaleKeys[ cast(int)time ].vector[ 0 ], bone.scaleKeys[ cast(int)time ].vector[ 1 ], bone.scaleKeys[ cast(int)time ].vector[ 2 ] );
		}
	
		if( bone.positionKeys.length == 0 && bone.rotationKeys.length == 0 && bone.scaleKeys.length  == 0 )
		{
			finalTransform = parentTransform * boneTransform * bone.nodeOffset;
			transforms[ bone.id ] = finalTransform * bone.offset;
		}
		else
		{
			finalTransform = parentTransform * boneTransform;
			transforms[ bone.id ] = finalTransform * bone.offset;
		}

        // Store the transform in the correct place and check children
        for( int i = 0; i < bone.children.length; i++ )
        {
            fillTransforms( transforms, bone.children[ i ], time, finalTransform );
        }
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    mat4 convertAIMatrix( aiMatrix4x4 aiMatrix )
    {
        mat4 matrix = mat4.identity;

        matrix[0][0] = aiMatrix.a1;
        matrix[0][1] = aiMatrix.a2;
        matrix[0][2] = aiMatrix.a3;
        matrix[0][3] = aiMatrix.a4;
        matrix[1][0] = aiMatrix.b1;
        matrix[1][1] = aiMatrix.b2;
        matrix[1][2] = aiMatrix.b3;
        matrix[1][3] = aiMatrix.b4;
        matrix[2][0] = aiMatrix.c1;
        matrix[2][1] = aiMatrix.c2;
        matrix[2][2] = aiMatrix.c3;
        matrix[2][3] = aiMatrix.c4;
        matrix[3][0] = aiMatrix.d1;
        matrix[3][1] = aiMatrix.d2;
        matrix[3][2] = aiMatrix.d3;
        matrix[3][3] = aiMatrix.d4;

        return matrix;
    }

    /**
     * TODO
     *
     * Params:
     *
     * Returns:
     */
    void shutdown()
    {

    }

    /**
     * TODO
     */
    shared struct AnimationSet
    {
        shared float duration;
        shared float fps;
        shared Bone animBones;
    }
	/**
     * TODO
     */
    shared class Bone
    {
        this( string boneName, int boneId) // , mat4 boneOffset, mat4 boneNodeOffset 
        {
            name = boneName;
			id = boneId;
			//offset = boneOffset;
			//nodeOffset = boneNodeOffset;
        }

        string name;
        shared int id;
        shared Bone[] children;

        shared vec3[] positionKeys;
        shared quat[] rotationKeys;
        shared vec3[] scaleKeys;
        shared mat4 offset;
		shared mat4 nodeOffset;
    }
}