/**
 * Defines audio related classes, such as the listener and emitter
 */
module dash.components.audio;
import dash.core.properties;
import dash.components.component;
import dash.utility, dash.utility.soloud;
import std.string;

mixin( registerComponents!q{dash.components.audio} );

/**
 * Listener object that hears sounds and sends them to the audio output device
 * (usually attaced to the camera)
 */
@yamlComponent( "Listener" )
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

	override void update()
	{
		Audio.soloud.set3dListenerAt(owner.transform.position.x,
		                             owner.transform.position.y,
		                             owner.transform.position.z);
	}
}

/**
 * Emitter object that plays sounds that listeners can hear if they are close enough
 */
@yamlComponent( "Emitter" )
class Emitter : Component
{
private:
	Modplug toPlay;
public:
	/**
	 * Create an emmiter object
	 */
	this()
	{
		// Constructor Code
	}

	override void initialize() {
		super.initialize;
		toPlay = Modplug.create();
	}

	// call:
	// emmiter.play( filename );
	void play( string soundName )
	{
		// Load in the sound
		toPlay.load( Audio.sounds[soundName].toStringz() );

		// play the sound from the location of the parent object
		Audio.soloud.play3d(toPlay,
							owner.transform.position.x,
		                    owner.transform.position.y,
		                    owner.transform.position.z);
	}
}

/**
 * TODO
 * implement sound struct
struct Sound
{
	Wav soundfile;
}
 */
 
final abstract class Audio
{
static:
//private:
	Soloud soloud;

public:
	string[string] sounds;

	void initialize()
	{
		soloud = Soloud.create();
		soloud.init();

		foreach( file; scanDirectory( Resources.Audio ) )
		{
			sounds[file.baseFileName] = file.relativePath;
		}
	}

	void shutdown()
	{
		soloud.deinit();
		soloud.destroy();
	}
}