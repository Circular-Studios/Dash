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

public:
	mixin( Property!_animationSet );

	this( string name, const(aiAnimation*) animation, const(aiNode*) boneHierarchy )
	{
		_animationSet.duration = cast(float)animation.mDuration;
		_animationSet.fps = cast(float)animation.mTicksPerSecond;

		_animationSet.boneAnimData = makeBoneFromNode( animation, boneHierarchy );
	}

	// PROBLEM! To get the parent you cant call makeBoneFromNode, otherwise it will be extra new nodes. Instead pass in parent node (if there is one)
	Bone makeBoneFromNode( const(aiAnimation*) animation, const(aiNode*) bones )
	{
		Bone temp = new Bone( cast(string)bones.mName.data );
		
		if( !(bones.mParent !is null) )
			temp.parent = makeBoneFromNode( animation, bones.mParent );

		for(int i = 0; i < bones.mNumChildren; i++)
		{
			temp.children ~= makeBoneFromNode( animation, bones.mChildren[i]);
		}

		assignCorrectAnimationData( animation, temp );

		return temp;
	}
	void assignCorrectAnimationData( const(aiAnimation*) animation, Bone boneToAssign )
	{
		// For each bone animation data
		for( int i = 0; i < animation.mNumChannels; i++)
		{
			// If the names match
			if( cast(string)animation.mChannels[ i ].mNodeName.data == boneToAssign.name )
			{
				// Assign the bone animation data to the bone
				boneToAssign.positionKeys = convertVectorArray( animation.mChannels[ i ].mPositionKeys,
																animation.mChannels[ i ].mNumPositionKeys );
			}
			else
			{
				//log( OutputType.Warning, "Bone ", i, " did not find a valid AnimNode pair." );
			}
		}
	}
	// Go through array of keys and convert/store in vector[]
	vec3[] convertVectorArray(const(aiVectorKey*) vectors, int numKeys)
	{
		vec3[] temp;
		for(int i = 0; i < numKeys; i++)
		{
			aiVector3D vector = vectors[i].mValue;
			temp ~= vec3(vector.x, vector.y, vector.z);
		}

		return temp;
	}
	
	// Find bone with name in our structure
	/*Bone findBoneWithName(string name, Bone bone)
	{
		if(name == bone.name)
		{
			return bone;
		}

		for(int i = 0; i < bone.children.length; i++)
		{
			Bone temp = findBoneWithName(name, bone.children[i]);
			if(temp !is null)
			{
				return temp;
			}
		}

		return null;
	}*/

	void shutdown()
	{

	}

	struct AnimationSet
	{
		float duration;
		float fps;
		Bone boneAnimData;
	}
	class Bone
	{
		this( string boneName )
		{
			name = boneName;
		}

		string name;
		Bone parent;
		Bone[] children;
		vec3[] positionKeys;
		//Quaternion[] rotationKeys;
		//vec3[] scaleKeys;
	}
}
