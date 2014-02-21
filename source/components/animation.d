module components.animation;

import components.component;

import derelict.assimp3.assimp;

import math.matrix, math.vector;

class Mesh : Component
{
public:
	//mixin Property!( "Bone[]", "bones", "public" );

	this( )
	{
		super( null );
	}

	this( aiAnimation animation, aiBone[] bones )
	{
		super( null );
	}


	class Bone
	{
		Bone parent;
		Bone[] children;
		Matrix!4 offset;
	}

	struct Animation
	{
		string name;
		float duration;
		float fps;
		float currentTime;
		BonePoses[] animData;
	}

	struct BonePoses
	{
		Vector!3[] positions;
		//Quaternion[] rotations;
		//Vector!3[] scales;
	}
	

}
