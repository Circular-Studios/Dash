module components.animation;

import core.properties;
import components.component, components.assetanimation;

import math.matrix, math.vector;

class Animation : Component
{
public:
	mixin Property!( "AssetAnimation", "animationData", "public" );
	mixin Property!( "int", "currentAnimation", "public" );
	mixin Property!( "float", "currentPosition", "public" );
	mixin Property!( "Bone[]", "currentPose", "public" );

	this( AssetAnimation assetAnimation)
	{
		super( null );

		currentAnimation = 0;
		currentPosition = 0.0f;
		animationData = assetAnimation;
		//currentPose = animationData.getPose();
	}

	override void update()
	{

	}

	override void shutdown()
	{

	}

	class Bone
	{
		Bone parent;
		Bone[] children;
		Matrix!4 offset;
	}
}