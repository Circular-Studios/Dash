/**
 * All classes dealing with using 3D skeletal animation
 */
module dash.components.animation;
import dash.core.properties;
import dash.components;
import dash.utility;

import derelict.assimp3.assimp;
import gl3n.linalg;
import std.string: fromStringz;
import std.conv: to;

/**
 * Animation object which handles all animation specific to the gameobject
 */
class Animation : Component
{
private:
    /// Asset animation that the gameobject is animating based off of
    AnimationData _animationData;
    /// Current animation out of all the animations in the asset animation
    int _currentAnim;
    /// Current time of the animation
    float _currentAnimTime;
    /// Bone transforms for the current pose
    mat4[] _currBoneTransforms;
    /// If the gameobject should be animating
    bool _animating;

    /// Animation to return to if _animateOnce is true
    int _returnAnimation;
    /// If the animation is animating once, then returning to _returnAnimation
    bool _animateOnce;

public:
    /// Bone transforms for the current pose (Passed to the shader)
    mixin( Property!_currBoneTransforms );

    /**
     * Create animation object based on asset animation
     */
    this( AnimationData assetAnimation )
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
            // Update currentanimtime based on deltatime and animations fps
            _currentAnimTime += Time.deltaTime * 24.0f;

            if( _currentAnimTime >= _animationData.animationSet[ _currentAnim ].duration * 24 - 1 )
            {
                _currentAnimTime = 0.0f;

                if( _animateOnce )
                {
                    _animateOnce = false;
                    _currentAnim = _returnAnimation;
                }
            }
        }

        // Calculate and store array of bonetransforms to pass to the shader
        currBoneTransforms = _animationData.getTransformsAtTime( _currentAnim, _currentAnimTime );
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
     * Switches the current animation
     */
    void changeAnimation( int animNumber, int startAnimTime )
    {
        if( animNumber < _animationData.animationSet.length )
        {
            _currentAnim = animNumber;
            _currentAnimTime = startAnimTime;
        }
        else
            logWarning( "Could not change to new animation, the animation did not exist." );
    }
    /**
    * Runs an animation once, then returns
    */
    void runAnimationOnce( int animNumber, int returnAnimNumber )
    {
        if( animNumber < _animationData.animationSet.length )
        {
            _animateOnce = true;
            _currentAnim = animNumber;
            _returnAnimation = returnAnimNumber;
            _currentAnimTime = 0;
        }
        else
            logWarning( "Could not change to new animation, the animation did not exist." );
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
class AnimationData : Asset
{
private:
    /// List of animations, containing all of the information specific to each
    AnimationSet[] _animationSet;
    /// Amount of bones
    int _numberOfBones;
    /// Hierarchy of bones for this animation
    Bone boneHierarchy;
    bool _isUsed;

public:
    /// List of animations, containing all of the information specific to each
    mixin( Property!_animationSet );
    /// Amount of bones
    mixin( Property!_numberOfBones );
    /// Whether or not the material is actually used.
    mixin( Property!( _isUsed, AccessModifier.Package ) );

    /**
     * Create the assetanimation, parsing all of the animation data
     *
     * Params:
     *      animations =    List of assimp animation/poses object
     *      numAnimations = Number of
     *      mesh =          Assimp mesh/bone object
     *      nodeHierarchy = Hierarchy of bones/filler nodes used for the animation
     */
    this( const(aiAnimation**) animations, int numAnimations, const(aiMesh*) mesh, const(aiNode*) nodeHierarchy )
    {
        super( Resource( "" ) );

        for( int i = 0; i < nodeHierarchy.mNumChildren; i++)
        {
            string name = nodeHierarchy.mChildren[ i ].mName.data.ptr.fromStringz().to!string;
            if( findBoneWithName( name, mesh ) != -1 )
            {
                boneHierarchy = makeBonesFromHierarchy( mesh, nodeHierarchy.mChildren[ i ] );
            }
        }

        for( int ii = 0; ii < numAnimations; ii++)
            addAnimationSet( animations[ ii ], 24 );
    }

    /**
     * Returns the animation as an addible component.
     */
    Animation getComponent()
    {
        return new Animation( this );
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
    Bone makeBonesFromHierarchy( const(aiMesh*) mesh, const(aiNode*) currNode )
    {
        //NOTE: Currently only works if each node is a Bone, works with bones without animation b/c of storing nodeOffset
        //NOTE: Needs to be reworked to support this in the future
        Bone bone;
        string name = currNode.mName.data.ptr.fromStringz().to!string;
        int boneNumber = findBoneWithName( name, mesh );

        if( boneNumber != -1 )
        {
            bone = new Bone( name, boneNumber );
            bone.offset = convertAIMatrix( mesh.mBones[ bone.boneNumber ].mOffsetMatrix );
            bone.nodeOffset = convertAIMatrix( currNode.mTransformation );
            _numberOfBones++;
        }

        for( int i = 0; i < currNode.mNumChildren; i++ )
        {
            string childName = currNode.mChildren[ i ].mName.data.ptr.fromStringz().to!string;
            int childBoneNumber = findBoneWithName( childName, mesh );

            // Ensure end nodes are bones, otherwise do not keep
            if( boneNumber != -1 && childBoneNumber != -1 )
                bone.children ~= makeBonesFromHierarchy( mesh, currNode.mChildren[ i ] );
            else if( childBoneNumber != -1 )
                return makeBonesFromHierarchy( mesh, currNode.mChildren[ i ] );
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
            if( name == mesh.mBones[ i ].mName.data.ptr.fromStringz )
            {
                return i;
            }
        }

        return -1;
    }

    void addAnimationSet( const(aiAnimation*) animation, int fps )
    {
        AnimationSet newAnimSet;
        newAnimSet.duration = cast(float)animation.mDuration;
        newAnimSet.fps = fps;
        for( int i = 0; i < _numberOfBones; i++)
        {
            newAnimSet.bonePoses ~= new BonePose();
        }
        addPoses( animation, boneHierarchy, newAnimSet );
        _animationSet ~= newAnimSet;
    }
    void addPoses( const(aiAnimation*) animation, Bone currBone, AnimationSet newAnimSet )
    {
        if( currBone.boneNumber != -1 )
        {
            assignAnimationData( animation, currBone.name, newAnimSet.bonePoses[ currBone.boneNumber ] );
        }

        // Add to children
        for( int i = 0; i < currBone.children.length; i++ )
        {
            addPoses( animation, currBone.children[ i ], newAnimSet );
        }
    }
    /**
     * Access the animation channels to find a match with the bone, then store its animation data
     *
     * Params:
     *      animation =    Assimp animation/poses object
     *      boneToAssign = Bone to assign the animation keys/poses
     */
    void assignAnimationData( const(aiAnimation*) animation, string boneName, BonePose poseToAssign )
    {
        for( int i = 0; i < animation.mNumChannels; i++)
        {
            if( animation.mChannels[ i ].mNodeName.data.ptr.fromStringz == boneName )
            {
                // Assign the bone animation data to the bone
                poseToAssign.positionKeys = convertVectorArray( animation.mChannels[ i ].mPositionKeys,
                                                                animation.mChannels[ i ].mNumPositionKeys );
                poseToAssign.scaleKeys = convertVectorArray( animation.mChannels[ i ].mScalingKeys,
                                                             animation.mChannels[ i ].mNumScalingKeys );
                poseToAssign.rotationKeys = convertQuat( animation.mChannels[ i ].mRotationKeys,
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
    mat4[] getTransformsAtTime( int animationNumber, float time )
    {
        mat4[] boneTransforms = new mat4[ _numberOfBones ];

        // Check shader/model
        for( int i = 0; i < _numberOfBones; i++)
        {
            boneTransforms[ i ] = mat4.identity;
        }

        fillTransforms( animationSet[ animationNumber ].bonePoses, boneTransforms, boneHierarchy, time, mat4.identity );

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
    void fillTransforms( BonePose[] bonePoses, mat4[] transforms, Bone bone, float time, mat4 parentTransform )
    {
        BonePose bonePose = bonePoses[ bone.boneNumber ];
        mat4 finalTransform;
        if( bonePose.positionKeys.length == 0 && bonePose.rotationKeys.length == 0 && bonePose.scaleKeys.length == 0 )
        {
            finalTransform = parentTransform * bone.nodeOffset;
            transforms[ bone.boneNumber ] = finalTransform * bone.offset;
        }
        else
        {
            mat4 boneTransform = mat4.identity;

            if( bonePose.positionKeys.length > cast(int)time )
            {
                boneTransform = boneTransform.translation( bonePose.positionKeys[ cast(int)time ].vector[ 0 ],
                                                           bonePose.positionKeys[ cast(int)time ].vector[ 1 ],
                                                           bonePose.positionKeys[ cast(int)time ].vector[ 2 ] );
            }
            if( bonePose.rotationKeys.length > cast(int)time )
            {
                boneTransform = boneTransform * bonePose.rotationKeys[ cast(int)time ].to_matrix!( 4, 4 );
            }
            if( bonePose.scaleKeys.length > cast(int)time )
            {
                boneTransform = boneTransform.scale( bonePose.scaleKeys[ cast(int)time ].vector[ 0 ],
                                                     bonePose.scaleKeys[ cast(int)time ].vector[ 1 ],
                                                     bonePose.scaleKeys[ cast(int)time ].vector[ 2 ] );
            }

            finalTransform = parentTransform * boneTransform;
            transforms[ bone.boneNumber ] = finalTransform * bone.offset;
        }

        // Check children
        for( int i = 0; i < bone.children.length; i++ )
        {
            fillTransforms( bonePoses, transforms, bone.children[ i ], time, finalTransform );
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
    vec3[] convertVectorArray( const(aiVectorKey*) vectors, int numKeys )
    {
        vec3[] keys;
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
    quat[] convertQuat( const(aiQuatKey*) quaternions, int numKeys )
    {
        quat[] keys;
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
    override void shutdown()
    {

    }

    /**
     * A single animation track, storing its bones and poses
     */
    struct AnimationSet
    {
        float duration;
        float fps;
        BonePose[] bonePoses;
    }
    /**
    * All the bone transforms/rotations/scales for a sc
    */
    class BonePose
    {
        vec3[] positionKeys;
        quat[] rotationKeys;
        vec3[] scaleKeys;
    }
    /**
     * A bone in the animation, storing everything it needs
     */
    class Bone
    {
        this( string boneName, int boneNum )
        {
            name = boneName;
            boneNumber = boneNum;
        }

        string name;
        int boneNumber;
        Bone[] children;

        mat4 offset;
        mat4 nodeOffset;
    }
}
