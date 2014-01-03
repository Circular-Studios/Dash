module testgame;
import core.dgame, core.gameobjectcollection;
import utility.output, utility.input;

import std.c.windows.windows;

@Game!TestGame class TestGame : DGame
{
	GameObjectCollection goc;
	
	override void onInitialize()
	{
		Output.printMessage( OutputType.Info, "Initializing..." );

		Input.addKeyDownEvent( VK_ESCAPE, ( uint kc ) { currentState = GameState.Quit; } );

		goc = new GameObjectCollection;
		goc.loadObjects;
	}
	
	override void onUpdate()
	{
		goc.apply( go => go.update() );
	}
	
	override void onDraw()
	{
		goc.apply( go => go.draw() );
	}

	override void onShutdown()
	{
		goc.apply( go => go.shutdown() );
	}
}
