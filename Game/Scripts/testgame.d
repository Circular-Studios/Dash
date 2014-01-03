module testgame;
import core.dgame, core.gameobjectcollection;
import utility.output, utility.input;

import std.c.windows.windows;

@Game!TestGame class TestGame : DGame
{
	GameObjectCollection goc;
	
	override void initialize()
	{
		Output.printMessage( OutputType.Info, "Initializing..." );

		Input.addKeyDownEvent( VK_ESCAPE, ( uint kc ) { currentState = GameState.Quit; } );

		//goc = new GameObjectCollection;
		//goc.loadObjects;
		//currentState = GameState.Quit;
	}
	
	override void update()
	{
		//goc.callFunction( go => go.update() );
	}
	
	override void draw() { }
	override void shutdown() { }
}
