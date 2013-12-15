module core.dgame;
import components.assets;
import graphics.graphics;
import utility.time;

enum GameState { Menu = 0, Game = 1, Reset = 2, Quit = 3 };

class DGame
{
public:
	GameState currentState;

	void run()
	{
		//////////////////////////////////////////////////////////////////////////
        // Initialize
        //////////////////////////////////////////////////////////////////////////

        // Init time
		Time.initialize();
		// Init tasks
		//TaskManager.initialize();

        start();

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
	void initialize()
	{

	}
	void update()
	{

	}
	void draw()
	{

	}
	void shutdown()
	{

	}

	//UserInterface ui;

private:
	void start()
	{
		currentState = GameState.Menu;
        //camera = null;

		//Config.initialize();
		Graphics.initialize();
		Assets.initialize();
		//Physics.initialize();

        //ui = new UserInterface( this );

        initialize();
	}

	void stop()
	{
		Assets.shutdown();
	}

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
