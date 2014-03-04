module components.assetanimation;
import core.properties;
import components.icomponent;
import utility.output;

import derelict.assimp3.assimp;
import gl3n.linalg;
import std.string;

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
		
		// Currently assuming bone hierarchy is in slot 1 and mesh transform is default
		_animationSet.animNodes = makeNodesFromNode( animation, mesh, boneHierarchy.mChildren[ 1 ], null );
	}

	// Each bone split up into four seperate nodes (translation -> preRotation -> Rotation -> Scale -> Bone)
	// Need to compile these four nodes into 1 node for each bone
	// Currently loading one bone in correctly, need to add in storing the rest of the bone data, then continuing on for children
	Node makeNodesFromNode( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) currNode, Node parent)
	{
		string name = cast(string)currNode.mName.data[ 0 .. currNode.mName.length ];
		int boneId = findNodeWithName( name, mesh );
		Node node;
		// If the node is the translation segment of a bone add bone based on all of its parts (the next couple of children nodes)
		// Else if the node is another segment of a bone add its data to the partial bone (the parent node)
		// Else if the node is a full bone add it
		if( checkEnd( name, "_$AssimpFbx$_Translation" ) )
		{
			node = new Node( name );
			node.id = boneId;
			assignAnimationData( animation, currNode, node, "Position" );
			/*currNode = currNode.mChildren[ 0 ];
			assignAnimationData( animation, node, "RotationP" );
			currNode = currNode.mChildren[ 0 ];
			assignAnimationData( animation, node, "Rotation" );
			currNode = currNode.mChildren[ 0 ];
			assignAnimationData( animation, node, "Scale" );
			currNode = currNode.mChildren[ 0 ];
			node.transform = convertAIMatrix( mesh.mBones[ node.id ].mOffsetMatrix );*/
		}
		else if( checkEnd( name, "_$AssimpFbx$_PreRotation" ) )
		{
			//assignAnimationData( animation, currNode, parent, "RotationP");
		}
		else if( checkEnd( name, "_$AssimpFbx$_Rotation" ) )
		{
			assignAnimationData( animation, currNode, parent, "Rotation");
		}
		else if( checkEnd( name, "_$AssimpFbx$_Scaling" ) )
		{
			assignAnimationData( animation, currNode, parent, "Scale");
		}
		else if( boneId != -1)
		{
			node = new Node( name );
			node.id = boneId;
			node.transform = convertAIMatrix( mesh.mBones[ node.id ].mOffsetMatrix );
			assignAnimationData( animation, currNode, node, "All" );
			
			_numberOfBones++;
		}

		// For each child node
		for( int i = 0; i < currNode.mNumChildren; i++ )
		{
			// Create it and assign to this node as a child
			if( node !is null)
				node.children ~= makeNodesFromNode( animation, mesh, currNode.mChildren[ i ], node );
			else
				makeNodesFromNode( animation, mesh, currNode.mChildren[ i ], parent );
		}
		
		return node;
	}
	void assignAnimationData( const(aiAnimation*) animation, const(aiNode)* nodeToCheck, Node nodeToAssign, string data )
	{
		// For each bone animation data
		for( int i = 0; i < animation.mNumChannels; i++)
		{
			const(aiNodeAnim*) temp = animation.mChannels[ i ];

			// If the names match
			if( animation.mChannels[ i ].mNodeName == nodeToCheck.mName )
			{
				string name = cast(string)animation.mChannels[ i ].mNodeName.data;

				// Assign the bone animation data to the bone
				if( data == "All" || data == "Position" )
				{
					nodeToAssign.positionKeys = convertVectorArray( animation.mChannels[ i ].mPositionKeys,
																animation.mChannels[ i ].mNumPositionKeys );
				}
				
				if( data == "All" || data == "Scale" )
				{
					nodeToAssign.scaleKeys = convertVectorArray( animation.mChannels[ i ].mScalingKeys,
																  animation.mChannels[ i ].mNumScalingKeys );
				}
				
				if( data == "All" || data == "RotationP" || data == "Rotation" )
				{
					nodeToAssign.rotationKeys = convertQuat( animation.mChannels[ i ].mRotationKeys,
															 animation.mChannels[ i ].mNumRotationKeys );
				}
				
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
			aiQuatKey quaternion = quaternions[ i ];
			keys ~= quat( quaternion.mValue.x, quaternion.mValue.y, quaternion.mValue.z, quaternion.mValue.w );
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

	// Check if string stringToTest ends with string end
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

	mat4[] getTransformsAtTime( float time )
	{
		mat4[] boneTransforms = new mat4[ _numberOfBones ];

		// Check shader/model
		/*for( int i = 0; i < _numberOfBones; i++)
		{
			boneTransforms[ i ] = mat4.identity;
		}*/

		//fillTransforms( boneTransforms, _animationSet.animNodes, time, mat4.identity );

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
			/*if( node.rotationKeys.length > 1 )
			{
				// Get bone rotation information at frame
				boneTransform = boneTransform * node.rotationKeys[ 50 ].to_matrix!( 4, 4 );
			}
			else
			{
				// No rotation animation for this bone, set to default first key
				boneTransform = boneTransform * node.rotationKeys[ 0 ].to_matrix!( 4, 4 );
			}*/
			//boneTransform.scale( node.scaleKeys[ 0 ].vector );
			if( node.positionKeys.length > 1 )
			{
				// Get bone rotation information at frame
				boneTransform.translation( node.positionKeys[ 50 ].vector );
			}
			else
			{
				// No rotation animation for this bone, set to default first key
				boneTransform.translation( node.positionKeys[ 0 ].vector );
			}
			
			finalTransform = boneTransform; //( boneTransform * parentTransform * node.transform );
			transforms[ node.id ] = finalTransform;
		}
		else
		{
			finalTransform = ( parentTransform * node.transform );
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
