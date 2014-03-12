/**
 * Defines the DGame class, the base class for all game logic.
 */
module core.dgame;
import core, components, graphics, utility, utility.awesomium;
import std.string;

/**
 * The states the game can be in.
 */
enum GameState
{
	/// Render the menu, don't step physics.
	Menu = 0,
	/// The main game state.
	Game = 1,
	/// Reload all assets at the beginning of the next cycle.
	Reset = 2,
	/// Quit the game and the end of this cycle.
	Quit = 3
};

/**
 * The main game loop manager. Meant to be overridden.
 */
class DGame
{
public:
	/// The instance to be running from
	static DGame instance;

	/// The main UI object
	static UserInterface mainUI;

	/// Current state of the game
	GameState currentState;

	/**
	 * Overrideable. Returns the name of the window.
	 */
	@property string title()
	{
		return "Dash";
	}

	/**
	 * Main Game loop.
	 */
	final void run()
	{

		// Init tasks
		//TaskManager.initialize();
        start();

        // Loop until there is a quit message from the window or the user.
        while( currentState != GameState.Quit )
        {
			if( currentState == GameState.Reset )
				reload();

			//////////////////////////////////////////////////////////////////////////
			// Update
			//////////////////////////////////////////////////////////////////////////

			// Platform specific program stuff
			Graphics.messageLoop();

			// Update time
			Time.update();

			// Update input
			Input.update();

			// Update webcore
			awe_webcore_update();

			// Update physics
			//if( currentState == GameState.Game )
			//	PhysicsController.stepPhysics( Time.deltaTime );

			// Do the updating of the child class.
			onUpdate();

			mainUI.update();

			//////////////////////////////////////////////////////////////////////////
			// Draw
			//////////////////////////////////////////////////////////////////////////

			// Begin drawing
			Graphics.beginDraw();

			// Draw in child class
			onDraw();

			//if( currentState == GameState.Menu )
				mainUI.draw();

			// End drawing
			Graphics.endDraw();
        }

        stop();
	}

	//static Camera camera;

protected:
	/**
	 * To be overridden, logic for when the game is being initalized.
	 */
	void onInitialize() { }
	/**
	 * To be overridden, called once per frame during the update cycle.
	 */
	void onUpdate() { }
	/**
	 * To be overridden, called once per frame during the draw cycle.
	 */
	void onDraw() { }
	/**
	 * To be overridden, called when the came is closing.
	 */
	void onShutdown() { }
	/**
	 * To be overridden, called when resetting and the state must be saved.
	 */
	void onSaveState() { }

private:
	/**
	 * Function called to initialize controllers.
	 */
	final void start()
	{
		currentState = GameState.Game;
        //camera = null;

		Config.initialize();
		Input.initialize();
		Output.initialize();
		Graphics.initialize();
		Assets.initialize();
		Prefabs.initialize();
		awe_webcore_initialize_default();
		//Physics.initialize();

        mainUI = new UserInterface();

        onInitialize();
	}

	/**
	 * Function called to shutdown controllers.
	 */
	final void stop()
	{
		onShutdown();
		awe_webcore_shutdown();
		Assets.shutdown();
		Graphics.shutdown();

		mainUI.shutdown();
	}

	/**
	 * Reloads content and yaml.
	 */
	final void reload()
	{
		stop();

		start();
	}

	/**
	 * Called when engine is resetting.
	 */
	final void saveState()
	{
		onSaveState();
	}
}

/**
 * Initializes reflection things.
 */
static this()
{
	foreach( mod; ModuleInfo )
	{
		foreach( klass; mod.localClasses )
		{
			// Find the appropriate game loop.
			if( klass.base == typeid(DGame) )
				DGame.instance = cast(DGame)klass.create();
		}
	}
}
