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
	Wav toPlay;
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
		toPlay = Wav.create();

	}

	// call:
	// emmiter.play(Audio.sounds["baseFileName"]);
	void play( string soundName )
	{

		/*string filePath = Audio.sounds[soundName];
		logInfo( "playing: ", filePath );
		toPlay = Wav.create();
		toPlay.load( filePath.toStringz() );
		Speech speech = Speech.create();
		speech.setText("hello".toStringz());*/
		toPlay.load( "C:\\Circular\\Sample-Dash-Game\\Audio\\airhorn.wav".toStringz() );

		auto result = Audio.soloud.play( toPlay, 1.0 );
		
		logInfo( Audio.soloud.getErrorString( result ) );
		/*Audio.soloud.play3d(toPlay,
							owner.transform.position.x,
		                    owner.transform.position.y,
		                    owner.transform.position.z);*/
		//logInfo( "playing: ", soundName, " with id: ", Audio.effects[soundName].objhandle );
		//Audio.soloud.play( Audio.effects[soundName] );
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

	Wav[string] effects;

	void initialize()
	{
		soloud = Soloud.create();
		soloud.init();
		foreach( file; scanDirectory( Resources.Audio ) )
		{
			sounds[file.baseFileName] = file.fullPath;

			/*effects[file.baseFileName] = Wav.create();
			effects[file.baseFileName].load( file.fullPath.toStringz );
			logInfo( "baseFileName: ", file.baseFileName );
			logInfo( "fullPath: ", file.fullPath.toStringz );*/
		}
	}

	void shutdown()
	{
		soloud.deinit();
		soloud.destroy();
	}
}