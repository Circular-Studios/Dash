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

		Input.addKeyDownEvent( Keys.Escape, ( uint kc ) { currentState = GameState.Quit; } );
		Input.addKeyDownEvent( Keys.F5, ( uint kc ) { currentState = GameState.Reset; } );

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
		Output.printMessage( OutputType.Info, "Shutting down..." );
		goc.apply( go => go.shutdown() );
	}

	override void onSaveState()
	{
		Output.printMessage( OutputType.Info, "Resetting..." );
	}
}
