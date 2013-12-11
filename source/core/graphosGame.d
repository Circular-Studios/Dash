module core.graphosgame;
import graphics.graphicscontroller;
import utility.time;

enum GameState { Menu = 0, Game = 1, Reset = 2, Quit = 3 };

class GraphosGame
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
		TaskManager.initialize();

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
				//GraphicsController.messageLoop();

				// Update time
				Time.update();

				// Update input
				InputController.update();

				// Update physics
				if( currentState == GameState.Game )
					PhysicsController.stepPhysics( Time.deltaTime );

				// Do the updating of the child class.
				update();

				//////////////////////////////////////////////////////////////////////////
				// Draw
				//////////////////////////////////////////////////////////////////////////

				// Begin drawing
				GraphicsController.getAdapter().beginDraw();

				// Draw in child class
				draw();

				// End drawing
				GraphicsController.getAdapter().endDraw();
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

	}
	void stop()
	{

	}
	void reset()
	{
		shutdown();

		initialize();
	}
}
