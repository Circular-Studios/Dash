module components.assetanimation;

import core.properties;
import components.component;

import derelict.assimp3.assimp;

import math.matrix, math.vector;

class AssetAnimation
{
public:
	mixin Property!( "AnimationSet", "animationSet", "public" );

	this( string name, const(aiAnimation*) animation, const(aiNode*) boneHierarchy )
	{
		animationSet.duration = cast(float)animation.mDuration;
		animationSet.fps = cast(float)animation.mTicksPerSecond;
		
		// For each bone
		for( int i = 0; i < animation.mNumMeshChannels; i++ )
		{

			// Append array of position keys 
			animationSet.boneAnimData ~= new Bone( cast(string)animation.mChannels[ i ].mNodeName.data,
											       convertVectorArray( animation.mChannels[ i ].mPositionKeys,
															           animation.mChannels[ i ].mNumPositionKeys ));
		}

		// For each bone
		for( int i = 0; i < animation.mNumMeshChannels; i++ )
		{
			// Find bone in node hierarchy
			const(aiNode*) bone = findNodeWithName( animation.mChannels[ i ].mNodeName, boneHierarchy );

			//boneAnimData[ i ].parent = bone.
		}
	}

	// Go through array of keys and convert/store in vector[]
	Vector!3[] convertVectorArray(const(aiVectorKey*) vectors, int numKeys)
	{
		Vector!3[] temp;
		for(int i = 0; i < numKeys; i++)
		{
			aiVector3D vector = vectors[i].mValue;
			temp ~= new Vector!3(vector.x, vector.y, vector.z);
		}

		return temp;
	}

	const(aiNode*) findNodeWithName(aiString name, const(aiNode*) node)
	{
		if(name == node.mName)
		{
			return node;
		}

		for(int i = 0; i < node.mNumChildren; i++)
		{
			const(aiNode*) temp = findNodeWithName(name, node.mChildren[i]);
			if(temp != null)
			{
				return temp;
			}
		}

		return null;
	}

	struct AnimationSet
	{
		float duration;
		float fps;
		Bone[] boneAnimData;
	}
	class Bone
	{
		this( string boneName, Vector!3[] positions )
		{
			name = boneName;
			positionKeys = positions;
		}

		string name;
		Bone parent;
		Bone[] children;
		Vector!3[] positionKeys;
		//Quaternion[] rotationKeys;
		//Vector!3[] scaleKeys;
	}
}
