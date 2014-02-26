module components.assetanimation;

import core.properties;
import components.component;

import derelict.assimp3.assimp;
import utility.output;

import gl3n.linalg;

class AssetAnimation
{
public:
	mixin Property!( "AnimationSet", "animationSet", "public" );
	mixin Property!( "int", "numberOfBones", "public" );
	mixin Property!( "int", "amountAnim", "public" );

	this( string name, const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) boneHierarchy )
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
			node.bone = new Bone();
			node.bone.id = nodeId;
			node.transform = convertAIMatrix( mesh.mBones[ node.bone.id ].mOffsetMatrix );
			assignCorrectAnimationData( animation, node );

			_numberOfBones++;
		}

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
				// Assign the bone animation data to the bone
				nodeToAssign.bone.positionKeys = convertVectorArray( animation.mChannels[ i ].mPositionKeys,
																animation.mChannels[ i ].mNumPositionKeys );
				int iii = nodeToAssign.bone.positionKeys.length;
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

		fillTransforms( boneTransforms, _animationSet.animNodes, time, mat4.identity );

		return boneTransforms;
	}

	void fillTransforms( mat4[] transforms, Node node, float time, mat4 parentTransform )
	{
		mat4 finalTransform;
		if( node.bone !is null )
		{
			// Calculate matrix based on node.bone data and time
			if( node.bone.positionKeys.length > 0 )
			{
				mat4 boneTransform = mat4.identity;
				//boneTransform.scale( node.bone.scaleKeys[ time ] );
				//boneTransform *= node.bone.rotationKeys[ time ].to_matrix!( 4, 4 );
				boneTransform.translate( node.bone.positionKeys[ 0 ].x, node.bone.positionKeys[ 0 ].y, node.bone.positionKeys[ 0 ].z );
			
				// FIX: Still need to get boneoffsets and multiply by it
				finalTransform = ( boneTransform * parentTransform * node.transform );
				transforms[ node.bone.id ] = finalTransform;
			}
			else
			{
				finalTransform = ( parentTransform * node.transform );
			} 
			
			transforms[ node.bone.id ] = finalTransform;
			for( int i = 0; i < node.children.length; i++ )
			{
				fillTransforms( transforms, node.children[ i ], time, finalTransform );
			}
		}
		else
		{
			for( int i = 0; i < node.children.length; i++ )
			{
				// FIX: Still need to get nodeTransform and multiply by it
				finalTransform = ( node.transform * parentTransform );
				fillTransforms( transforms, node.children[ i ], time, finalTransform );
			}
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

	/*final void updateMatrix()
	{
		_matrix = mat4.identity;
		// Scale
		_matrix.scale( scale.x, scale.y, scale.z );
		// Rotate
		_matrix = _matrix * rotation.to_matrix!( 4, 4 );
		// Translate
		_matrix.translate( position.x, position.y, position.z );

		_matrixIsDirty = false;
	}*/

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
		Node parent;
		Node[] children;
		Bone* bone;
		mat4 transform;
	}
	struct Bone
	{
		int id;
		vec3[] positionKeys;
		//Quaternion[] rotationKeys;
		//vec3[] scaleKeys;
	}
}
