module components.animation;

import core.properties;
import components.component, components.assetanimation;

import gl3n.linalg;

class Animation : Component
{
public:
	mixin Property!( "AssetAnimation", "animationData", "private" );
	mixin Property!( "int", "currentAnim", "private" );
	mixin Property!( "float", "currentAnimTime", "private" );
	mixin Property!( "mat4[]", "currBoneTransforms", "public" );

	this( AssetAnimation assetAnimation)
	{
		super( null );

		currentAnim = 0;
		currentAnimTime = 0.0f;
		animationData = assetAnimation;
		//currentPose = animationData.getPose();
	}

	override void update()
	{
		getFrameTransforms( 0.0f );
	}

	override void shutdown()
	{

	}

	void getFrameTransforms( float changeInTime )
	{
		// Update currentanimtime based on changeintime
		
		// Calculate and store array of bonetransforms to pass to the shader
		currBoneTransforms = animationData.getTransformsAtTime( currentAnimTime );
	}
}