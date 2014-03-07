module components.animation;
import core.properties;
import components.icomponent, components.assetanimation;

import gl3n.linalg;

class Animation : IComponent
{
private:
	AssetAnimation _animationData;
	int _currentAnim;
	float _currentAnimTime;
	mat4[] _currBoneTransforms;

public:
	mixin( Property!_animationData );
	mixin( Property!_currentAnim );
	mixin( Property!_currentAnimTime );
	mixin( Property!_currBoneTransforms );

	this( AssetAnimation assetAnimation)
	{
		_currentAnim = 0;
		_currentAnimTime = 0.0f;
		_animationData = assetAnimation;
	}

	override void update() 
	{
		getFrameTransforms( 0.0f );
	}

	override void shutdown() { }

	void getFrameTransforms( float changeInTime )
	{
		// Update currentanimtime based on changeintime
		_currentAnimTime += 0.002;

		if( _currentAnimTime > 96.0f )
		{
			_currentAnimTime = 0.0f;
		}

		// Calculate and store array of bonetransforms to pass to the shader
		currBoneTransforms = animationData.getTransformsAtTime( _currentAnimTime );
	}
}