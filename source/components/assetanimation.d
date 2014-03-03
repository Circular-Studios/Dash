module components.assetanimation;
import core.properties;
import components.icomponent;
import utility.output;

import derelict.assimp3.assimp;
import gl3n.linalg;

class AssetAnimation
{
private:
	AnimationSet _animationSet;
	int _numberOfBones;
	int _amountAnim;

public:
	mixin( Property!_animationSet );
	mixin( Property!_numberOfBones );
	mixin( Property!_amountAnim );

	this( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) boneHierarchy )
	{
		_animationSet.duration = cast(float)animation.mDuration;
		_animationSet.fps = cast(float)animation.mTicksPerSecond;
		
		_animationSet.animNodes = makeNodesFromNode( animation, mesh, boneHierarchy, null );
	}

	// Currently some actual bones do not have keys and some nodes do have keys? Why?
	// Pretty sure animation keys correct, if no data I believe the bones never change
	Node makeNodesFromNode( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) nodes, Node parent )
	{
		// Create this node
		Node node = new Node( cast(string)nodes.mName.data );
		node.transform = convertAIMatrix( nodes.mTransformation );

		// If this node is a bone
		int nodeId = findNodeWithName( node.name, mesh );
		if( nodeId != -1 )
		{
			// Create bone and assign bone data
			node.id = nodeId;
			node.transform = convertAIMatrix( mesh.mBones[ node.id ].mOffsetMatrix );
		
			_numberOfBones++;
		}

		assignCorrectAnimationData( animation, node );

		// Assign parent
		if( parent !is null )
			node.parent = parent;
		
		// For each child node
		for( int i = 0; i < nodes.mNumChildren; i++ )
		{
			// Create it and assign to this node as a child
			node.children ~= makeNodesFromNode( animation, mesh, nodes.mChildren[ i ], node );
		}
		
		return node;
	}
	void assignCorrectAnimationData( const(aiAnimation*) animation, Node nodeToAssign )
	{
		// For each bone animation data
		for( int i = 0; i < animation.mNumChannels; i++)
		{
			// If the names match
			if( cast(string)animation.mChannels[ i ].mNodeName.data == nodeToAssign.name )
			{
				string name = cast(string)animation.mChannels[ i ].mNodeName.data;

				// Assign the bone animation data to the bone
				nodeToAssign.positionKeys = convertVectorArray( animation.mChannels[ i ].mPositionKeys,
																animation.mChannels[ i ].mNumPositionKeys );
				nodeToAssign.scaleKeys = convertVectorArray( animation.mChannels[ i ].mScalingKeys,
																  animation.mChannels[ i ].mNumScalingKeys );
				nodeToAssign.rotationKeys = convertQuat( animation.mChannels[ i ].mRotationKeys,
															  animation.mChannels[ i ].mNumRotationKeys );

				int iii = nodeToAssign.positionKeys.length;
				const(aiNodeAnim*) temp = animation.mChannels[ i ];
				_amountAnim++;
			}
			else
			{
				//log( OutputType.Warning, "Bone ", i, " did not find a valid AnimNode pair." );
			}
		}
	}
	// Go through array of keys and convert/store in vector[]
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
	// Go through array of keys and convert/store quat
	quat[] convertQuat( const(aiQuatKey*) quaternions, int numKeys )
	{
		quat[] keys;
		for( int i = 0; i < numKeys; i++ )
		{
			aiQuaternion quaternion = quaternions[ i ].mValue;
			keys ~= quat( quaternion.x, quaternion.y, quaternion.z, quaternion.w );
			int ii = 0;
		}

		return keys;
	}

	// Find bone with name in our structure
	int findNodeWithName( string name, const(aiMesh*) mesh )
	{
		for( int i = 0; i < mesh.mNumBones; i++ )
		{
			if( name == cast(string)mesh.mBones[ i ].mName.data )
			{
				return i;
			}
		}

		return -1;
	}

	mat4[] getTransformsAtTime( float time )
	{
		mat4[] boneTransforms = new mat4[ _numberOfBones ];

		// Check shader/model
		/*for( int i = 0; i < _numberOfBones; i++)
		{
			boneTransforms[ i ] = mat4.identity;
		}*/

		fillTransforms( boneTransforms, _animationSet.animNodes, time, mat4.identity );

		return boneTransforms;
	}

	// NOTE: Where assigncorrectanimation data is going to cause issues
	// NOTE: First pose should not modify the object, same position? Why?
	void fillTransforms( mat4[] transforms, Node node, float time, mat4 parentTransform )
	{
		// Calculate matrix based on node.bone data and time
		mat4 finalTransform;
		if( node.rotationKeys.length > 0 )
		{
			mat4 boneTransform = mat4.identity;
			//boneTransform.scale( node.scaleKeys[ 0 ].vector );
			boneTransform = boneTransform * node.rotationKeys[ 60 ].to_matrix!( 4, 4 );
			//boneTransform.translation( node.positionKeys[ 0 ].vector );
			
			finalTransform = ( boneTransform * parentTransform * node.transform );
			transforms[ node.id ] = finalTransform;
		}
		else
		{
			//finalTransform = ( parentTransform * node.transform );
		} 
		
		// Store the transform in the correct place and check children
		for( int i = 0; i < node.children.length; i++ )
		{
			fillTransforms( transforms, node.children[ i ], time, finalTransform );
		}
	}

	mat4 convertAIMatrix( aiMatrix4x4 aiMatrix )
	{
		mat4 matrix = mat4.identity;

		matrix[0][0] = aiMatrix.a1;
		matrix[1][0] = aiMatrix.a2;
		matrix[2][0] = aiMatrix.a3;
		matrix[3][0] = aiMatrix.a4;
		matrix[0][1] = aiMatrix.b1;
		matrix[1][1] = aiMatrix.b2;
		matrix[2][1] = aiMatrix.b3;
		matrix[3][1] = aiMatrix.b4;
		matrix[0][2] = aiMatrix.c1;
		matrix[1][2] = aiMatrix.c2;
		matrix[2][2] = aiMatrix.c3;
		matrix[3][2] = aiMatrix.c4;
		matrix[0][3] = aiMatrix.d1;
		matrix[1][3] = aiMatrix.d2;
		matrix[2][3] = aiMatrix.d3;
		matrix[3][3] = aiMatrix.d4;

		return matrix;
	}



	void shutdown()
	{

	}

	struct AnimationSet
	{
		float duration;
		float fps;
		Node animNodes;
	}
	class Node
	{
		this( string nodeName )
		{
			name = nodeName;
		}

		string name;
		int id;
		Node parent;
		Node[] children;
		
		vec3[] positionKeys;
		quat[] rotationKeys;
		vec3[] scaleKeys;
		mat4 transform;
	}
}
