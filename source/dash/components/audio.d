/**
 * Defines audio related classes, such as the listener and emitter
 */
module dash.components.audio;
import dash.core.properties, dash.components, dash.utility, dash.utility.bindings.soloud;
import std.string;

/**
 * Listener object that hears sounds and sends them to the audio output device
 * (usually attaced to the camera)
 */
class Listener : ComponentReg!Listener
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
        Audio.soloud.update3dAudio();
        Audio.soloud.set3dListenerAt(owner.transform.position.x,
                                     owner.transform.position.y,
                                     owner.transform.position.z);
    }
}

/**
 * Emitter object that plays sounds that listeners can hear
 */
class Emitter : ComponentReg!Emitter
{
private:
    Modplug toPlay;
    uint[] handles;
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


    /**
     * Plays a sound that will follow the emitter for however long you set the length to be.
     */
    void playFollow( string soundName ) {
        // Load in the sound
        toPlay.load( Audio.sounds[soundName].toStringz() );

        // play the sound from the location of the parent object
        // and set the sound to move with the emitter
        handles ~= Audio.soloud.play3d( toPlay,
                                        owner.transform.position.x,
                                        owner.transform.position.y,
                                        owner.transform.position.z );

    }

    override void update()
    {
        foreach_reverse( i, handle; handles )
        {
            if( !Audio.soloud.isValidVoiceHandle( handle ) )
            {
                auto end = handles[i+1..$];
                handles = handles[0..i];
                handles ~= end;
            } else {
                Audio.soloud.set3dSourcePosition( handle,
                                                  owner.transform.position.x,
                                                  owner.transform.position.y,
                                                  owner.transform.position.z );
            }
        }
    }


    
    void playFollow( string soundName, float soundLength )
    {

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
