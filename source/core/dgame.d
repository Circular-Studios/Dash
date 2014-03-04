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

		string URL = "http://google.com";
		string OUTFILE = "./result.jpg";
		
		// Wait for WebView to finish loading the page
		while(awe_webview_is_loading_page(webView))
			awe_webcore_update();
		
		// Render our WebView to a buffer
		const(awe_renderbuffer)* buffer = awe_webview_render(webView);
		
		// Make sure our buffer is not NULL; WebView::render will
		// return NULL if the WebView process has crashed.
		if(buffer !is null) {
			// Create our filename string
			awe_string* file_str = awe_string_create_from_ascii(OUTFILE.toStringz(), OUTFILE.length);
			
			// Save our RenderBuffer directly to a JPEG image
			awe_renderbuffer_save_to_jpeg(buffer, file_str, 90);
			
			// Destroy our filename string
			awe_string_destroy(file_str);
		}
		
		// Destroy our WebView instance


		// Init tasks
		//TaskManager.initialize();
		/*
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

			//////////////////////////////////////////////////////////////////////////
			// Draw
			//////////////////////////////////////////////////////////////////////////

			// Begin drawing
			Graphics.beginDraw();

			// Draw in child class
			onDraw();

			// End drawing
			Graphics.endDraw();
        }

        stop();*/
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

        //ui = new UserInterface( this );

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
