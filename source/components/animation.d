module components.animation;
import core.properties;
import components.icomponent, components.assetanimation;

import gl3n.linalg;

shared class Animation : IComponent
{
private:
	AssetAnimation _animationData;
	int _currentAnimation;
	float _currentPosition;
	Bone[] _currentPose;

public:
	mixin( Property!_animationData );
	mixin( Property!_currentAnimation );
	mixin( Property!_currentPosition );
	mixin( Property!_currentPose );

	this( shared AssetAnimation assetAnimation)
	{
		currentAnimation = 0;
		currentPosition = 0.0f;
		animationData = assetAnimation;
		//currentPose = animationData.getPose();
	}

	override void update() { }

	override void shutdown() { }

	class Bone
	{
		Bone parent;
		Bone[] children;
		mat4 offset;
	}
}