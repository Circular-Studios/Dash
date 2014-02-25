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

	this( string name, const(aiAnimation*) animation, const(aiNode*) boneHierarchy )
	{
		_animationSet.duration = cast(float)animation.mDuration;
		_animationSet.fps = cast(float)animation.mTicksPerSecond;
		
		_animationSet.boneAnimData = makeBonesFromNode( animation, boneHierarchy, null );
	}
	
	// PROBLEM! To get the parent you cant call makeBoneFromNode, otherwise it will be extra new nodes. Instead pass in parent node (if there is one)
	Bone makeBonesFromNode( const(aiAnimation*) animation, const(aiNode*) bones, Bone parent )
	{
		Bone bone = new Bone();
		bone.name = cast(string)bones.mName.data;
		
		if( parent !is null )
			bone.parent = parent;
		
		for(int i = 0; i < bones.mNumChildren; i++)
		{
			bone.children ~= makeBonesFromNode( animation, bones.mChildren[i], bone );
		}
		
		assignCorrectAnimationData( animation, bone );
		
		return bone;
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
		vec3[] keys;
		for( int i = 0; i < numKeys; i++ )
		{
			aiVector3D vector = vectors[ i ].mValue;
			keys ~= vec3(vector.x, vector.y, vector.z);
		}

		return keys;
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
		string name;
		Bone parent;
		Bone[] children;
		vec3[] positionKeys;
		//Quaternion[] rotationKeys;
		//vec3[] scaleKeys;
	}
}
