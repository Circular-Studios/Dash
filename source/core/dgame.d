/**
 * Defines the DGame class, the base class for all game logic.
 */
module core.dgame;
import core.gameobjectcollection;
import components.assets;
import graphics.graphics;
import scripting.scripts;
import utility.time, utility.config, utility.output;

enum GameState { Menu = 0, Game = 1, Reset = 2, Quit = 3 };

class DGame
{
public:
	GameState currentState;

	/**
	 * Main Game loop.
	 */
	final void run()
	{
		// Init tasks
		//TaskManager.initialize();

        start();

		auto goc = new GameObjectCollection;
		goc.loadObjects;

        // Loop until there is a quit message from the window or the user.
        while( currentState != GameState.Quit )
        {
			//try
			{
				if( currentState == GameState.Reset )
					reset();

				//////////////////////////////////////////////////////////////////////////
				// Update
				//////////////////////////////////////////////////////////////////////////

				// Platform specific program stuff
				Graphics.window.messageLoop();

				// Update time
				Time.update();

				// Update input
				//Input.update();

				// Update physics
				//if( currentState == GameState.Game )
				//	PhysicsController.stepPhysics( Time.deltaTime );

				// Do the updating of the child class.
				update();

				//////////////////////////////////////////////////////////////////////////
				// Draw
				//////////////////////////////////////////////////////////////////////////

				// Begin drawing
				Graphics.adapter.beginDraw();

				// Draw in child class
				draw();

				// End drawing
				Graphics.adapter.endDraw();
			}
			/*
			catch (std::exception e)
			{
			OutputController::PrintMessage( OutputType::OT_ERROR, e.what() );
			system( "pause" );
			break;
			}
			*/
        }

        stop();
	}

	//static Camera camera;

protected:
	/**
	 * To be overridden, logic for when the game is being initalized.
	 */
	void initialize() { }
	/**
	 * To be overridden, called once per frame during the update cycle.
	 */
	void update() { }
	/**
	 * To be overridden, called once per frame during the draw cycle.
	 */
	void draw()	{ }
	/**
	 * To be overridden, called when the came is closing.
	 */
	void shutdown() { }

	//UserInterface ui;

private:
	/**
	 * Function called to initialize controllers.
	 */
	void start()
	{
		currentState = GameState.Menu;
        //camera = null;

		Config.initialize();
		Output.initialize();
		Scripts.initialize();
		Graphics.initialize();
		Assets.initialize();
		//Physics.initialize();

        //ui = new UserInterface( this );

        initialize();
	}

	/**
	 * Function called to shutdown controllers.
	 */
	void stop()
	{
		Assets.shutdown();
	}

	/**
	 * Called when engine is resetting.
	 */
	void reset()
	{
		shutdown();

		// Stop controllers
		Assets.shutdown();

		// Reinitialize controllers
		Assets.initialize();

		initialize();
	}
}
