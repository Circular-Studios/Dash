/**
 * All classes dealing with using 3D skeletal animation
 */
module components.animation;
import core.properties;
import components.icomponent;
import utility.output, utility.time;

import derelict.assimp3.assimp;
import gl3n.linalg;

/**
 * Animation object which handles all animation specific to the gameobject
 */
shared class Animation : IComponent
{
private:
	/// Asset animation that the gameobject is animating based off of
    shared AssetAnimation _animationData;
	/// Current animation out of all the animations in the asset animation
    shared int _currentAnim;
	/// Current time of the animation
    shared float _currentAnimTime;
	/// Bone transforms for the current pose
    shared mat4[] _currBoneTransforms;
	/// If the gameobject should be animating
    shared bool _animating;

public:
	/// Asset animation that the gameobject is animating based off of
	mixin( Property!_animationData );
	/// Current animation out of all the animations in the asset animation
	mixin( Property!_currentAnim );
	/// Current time of the animation
	mixin( Property!_currentAnimTime );
    /// Bone transforms for the current pose (Passed to the shader)
    mixin( Property!_currBoneTransforms );
	/// If the gameobject should be animating
	mixin( Property!_animating );

    /**
     * Create animation object based on asset animation
     */
    this( shared AssetAnimation assetAnimation )
    {
        _currentAnim = 0;
        _currentAnimTime = 0.0f;
        _animationData = assetAnimation;
        _animating = true;
    }

    /**
     * Updates the animation, updating time and getting a pose based on time
     */
    override void update() 
    {
        if( _animating )
        {
            // Update currentanimtime based on deltaintime and animations fps
            _currentAnimTime += Time.deltaTime * 24.0f;

            if( _currentAnimTime >= 96.0f )
            {
                _currentAnimTime = 0.0f;
            }

            // Calculate and store array of bonetransforms to pass to the shader
            currBoneTransforms = _animationData.getTransformsAtTime( _currentAnimTime );
        }
    }

	/**
	* Continue animating.
	*/
    void play()
    {
        _animating = true;
    }
    /**
     * Pause the animation
     */
    void pause()
    {
        _animating = false;
    }
    /**
     * Stops the animation, moving to the beginning
     */
    void stop()
    {
        _animating = false;
        _currentAnimTime = 0.0f;
    }

	/**
	* Shutdown the gameobjects animation data
	*/
    override void shutdown() 
    { 

    }
}

/**
 * Stores the animation skeleton/bones, stores the animations poses, and makes this information accessible to gameobjects
 */
shared class AssetAnimation
{
private:
	/// List of animations, containing all of the information specific to each
    shared AnimationSet _animationSet;
	/// Amount of bones
    shared int _numberOfBones;

public:
    /// List of animations, containing all of the information specific to each
    mixin( Property!_animationSet );
    /// Amount of bones
    mixin( Property!_numberOfBones );

    /**
     * Create the assetanimation, parsing all of the animation data
     *
	 * Params:
	 *      animation =     Assimp animation/poses object
	 *      mesh =          Assimp mesh/bone object
	 *      boneHierarchy = Hierarchy of bones/filler nodes used for the animation
     */
    this( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) boneHierarchy )
    {
        _animationSet.duration = cast(float)animation.mDuration;
        _animationSet.fps = cast(float)animation.mTicksPerSecond;

		// NOTE: Node hierarchy must currently be the first child or it crashes
		_animationSet.animBones = makeBonesFromHierarchy( animation, mesh, boneHierarchy );
    }

    /**
     * Recurse the node hierarchy, parsing it into a usable bone hierarchy 
	 *
	 * Params:
	 *      animation = Assimp animation/poses object
	 *      mesh =      Assimp mesh/bone object
	 *      currNode =  The current node checking in the hierarchy
     *
     * Returns: The bone based off of the currNode data
     */
    shared(Bone) makeBonesFromHierarchy( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) currNode )
    { 
	    //NOTE: Currently only works if each node is a Bone, works with bones without animation b/c of storing nodeOffset
		//NOTE: Needs to be reworked to support this in the future
        string name = cast(string)currNode.mName.data[ 0 .. currNode.mName.length ];
        int boneNumber = findBoneWithName( name, mesh );
        shared Bone bone;

        if( boneNumber != -1 && name )
        {
            bone = new shared Bone( name, boneNumber );
			
			bone.offset = convertAIMatrix( mesh.mBones[ bone.boneNumber ].mOffsetMatrix );
			bone.nodeOffset = convertAIMatrix( currNode.mTransformation );

            assignAnimationData( animation, bone );

            _numberOfBones++;
        }

        for( int i = 0; i < currNode.mNumChildren; i++ )
        {
            if( boneNumber != -1 )
                bone.children ~= makeBonesFromHierarchy( animation, mesh, currNode.mChildren[ i ] );
            else
                return makeBonesFromHierarchy( animation, mesh, currNode.mChildren[ i ] );
        }

        return bone;
    }
	/**
	* Get a bone number by matching name bones in mesh
	*
	* Params:
	*      name = Name searching for
	*      mesh = Mesh containing bones to check
	*
	* Returns: Bone number of desired bone
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
     * Access the animation channels to find a match with the bone, then store its animation data
     *
	 * Params:
	 *      animation =    Assimp animation/poses object
	 *      boneToAssign = Bone to assign the animation keys/poses
     */
    void assignAnimationData( const(aiAnimation*) animation, shared Bone boneToAssign )
    {
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
     * Called by gameobject animation components to get an animation pose
     *
     * Params:
	 *      time = The current animations time
     *
     * Returns: The boneTransforms, returned to the gameobject animation component
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
     * Recurse the bone hierarchy, filling up the bone transforms along the way
     *
	 * Params:
	 *      transforms =      The boneTransforms to fill up
	 *      bone =            The current bone checking
	 *      time =            The animations current time
	 *      parentTransform = The parents transform (which effects this bone)
     */
    void fillTransforms( shared mat4[] transforms, shared Bone bone, shared float time, shared mat4 parentTransform )
    {
        shared mat4 finalTransform;
		if( bone.positionKeys.length == 0 && bone.rotationKeys.length == 0 && bone.scaleKeys.length  == 0 )
		{
			finalTransform = parentTransform * bone.nodeOffset;
			transforms[ bone.boneNumber ] = finalTransform * bone.offset;
		}
		else
		{
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

			finalTransform = parentTransform * boneTransform;
			transforms[ bone.boneNumber ] = finalTransform * bone.offset;
		}

        // Check children
        for( int i = 0; i < bone.children.length; i++ )
        {
            fillTransforms( transforms, bone.children[ i ], time, finalTransform );
        }
    }

	/**
	* Converts a aiVectorKey[] to vec3[].
	 *
	 * Params:
	 *      quaternions = aiVectorKey[] to be converted
	 *      numKeys =     Number of keys in vector array
	 *
	 * Returns: The vectors in vector[] format
	 */ 
    shared( vec3[] ) convertVectorArray( const(aiVectorKey*) vectors, int numKeys ) {
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
	 *      quaternions = aiQuatKey[] to be converted
	 *      numKeys =     Number of keys in quaternions array
	 *
	 * Returns: The quaternions in quat[] format
	 */
    shared( quat[] ) convertQuat( const(aiQuatKey*) quaternions, int numKeys )
    {
        shared quat[] keys;
        for( int i = 0; i < numKeys; i++ )
        {
            aiQuatKey quaternion = quaternions[ i ];
            keys ~= quat( quaternion.mValue.w, quaternion.mValue.x, quaternion.mValue.y, quaternion.mValue.z );
        }

        return keys;
    }
    /**
     * Converts an aiMatrix to a mat4
     *
     * Params:
     *      aiMatrix = Matrix to be converted
	 *
     * Returns: The matrix in mat4 format
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
     * Shutdown the animation bone/pose data
     */
    void shutdown()
    {

    }

    /**
     * A single animation track, storing its bones and poses
     */
    shared struct AnimationSet
    {
        shared float duration;
        shared float fps;
        shared Bone animBones;
    }
	/**
     * A bone in the animation, storing everything it needs
     */
    shared class Bone
    {
        this( string boneName, int boneNum )
        {
            name = boneName;
			boneNumber = boneNum;
        }

        string name;
        shared int boneNumber;
        shared Bone[] children;

        shared vec3[] positionKeys;
        shared quat[] rotationKeys;
        shared vec3[] scaleKeys;
        shared mat4 offset;
		shared mat4 nodeOffset;
    }
}