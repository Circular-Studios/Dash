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
	mixin Property!( "int", "amount", "public" );
	mixin Property!( "int", "amountAnim", "public" );

	this( string name, const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) boneHierarchy )
	{
		_animationSet.duration = cast(float)animation.mDuration;
		_animationSet.fps = cast(float)animation.mTicksPerSecond;
		
		_animationSet.boneAnimData = makeBonesFromNode( animation, mesh, boneHierarchy, null );
	}

	// Convert 'bones' to 'nodes' (They are not all bones, yet are needed to place bones in correct position
	// Currently some actual bones do not have keys and some nodes do have keys? Why?
	// Position keys correct, either 1 or amt of animation
	
	Bone makeBonesFromNode( const(aiAnimation*) animation, const(aiMesh*) mesh, const(aiNode*) bones, Bone parent )
	{
		Bone bone = new Bone();
		bone.name = cast(string)bones.mName.data;
		bone.id = findBoneWithName( bone.name, mesh );

		if(bone.id != -1)
		{
			_amount++;
		}
		
		assignCorrectAnimationData( animation, bone );

		if( parent !is null )
			bone.parent = parent;
		
		for(int i = 0; i < bones.mNumChildren; i++)
		{
			bone.children ~= makeBonesFromNode( animation, mesh, bones.mChildren[i], bone );
		}
		
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
				int iii = boneToAssign.positionKeys.length;
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

	mat4[] getTransformsAtTime( float time )
	{
		mat4[] boneTransforms;

		return boneTransforms;
	}
	
	// Find bone with name in our structure
	int findBoneWithName( string name, const(aiMesh*) mesh )
	{
		for(int i = 0; i < mesh.mNumBones; i++)
		{
			if( name == cast(string)mesh.mBones[i].mName.data )
			{
				return i;
			}
		}

		return -1;
	}

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
		int id;
		Bone parent;
		Bone[] children;
		vec3[] positionKeys;
		//Quaternion[] rotationKeys;
		//vec3[] scaleKeys;
	}
}
