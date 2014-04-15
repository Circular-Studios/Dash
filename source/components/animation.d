/**
 * TODO
 */
module components.animation;
import core.properties;
import components.icomponent, components.assetanimation;

import gl3n.linalg;

/**
 * TODO
 */
shared class Animation : IComponent
{
private:
    shared AssetAnimation _animationData;
    shared int _currentAnim;
    shared float _currentAnimTime;
    shared mat4[] _currBoneTransforms;
    shared bool _animating;

public:
    /// TODO
    mixin( Property!_animationData );
    /// TODO
    mixin( Property!_currentAnim );
    /// TODO
    mixin( Property!_currentAnimTime );
    /// TODO
    mixin( Property!_currBoneTransforms );

    /**
     * TODO
     */
    this( shared AssetAnimation assetAnimation )
    {
        _currentAnim = 0;
        _currentAnimTime = 0.0f;
        _animationData = assetAnimation;
        _animating = true;
    }

    /**
     * Updates the animation's bones.
     */
    override void update() 
    {
        if( _animating )
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

    /**
     * TODO
     */
    override void shutdown() 
    { 

    }

    /**
     * Stops the animation from updating.
     */
    void pause()
    {
        _animating = false;
    }

    /**
     * Stops the animation from updating and resets it.
     */
    void stop()
    {
        _animating = false;
        _currentAnimTime = 0.0f;
    }

    /**
     * Allows animation to update.
     */
    void play()
    {
        _animating = true;
    }
}