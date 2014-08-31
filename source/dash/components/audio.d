/**
 * Defines audio related classes, such as the listener and emitter
 */
module dash.components.audio;
import dash.core.properties;
import dash.components.component;
import dash.utility.soloud;

/**
 * Listener object that hears sounds and sends them to the audio output device
 * (usually attaced to the camera)
 */
class Listener : Component
{
private:

public:
	/**
	 * Create a listener object 
	 */
	this()
	{
		// Constructor code
	}
}

/**
 * Emitter object that plays sounds that listeners can hear if they are close enough
 */
class Emitter : Component
{
private:

public:
	/**
	 * Create an emmiter object
	 */
	this()
	{
		// Constructor Code
	}
}
