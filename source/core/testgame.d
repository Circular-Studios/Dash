module core.testgame;
import core.dgame, core.gameobjectcollection;
import utility.output;

@Game!TestGame class TestGame : DGame
{
	GameObjectCollection goc;

	override void initialize()
	{
		Output.printMessage( OutputType.Info, "Initializing..." );
		goc = new GameObjectCollection;
		goc.loadObjects;
	}

	override void update()
	{
		goc.callFunction( go => go.update() );
	}

	override void draw() { }
	override void shutdown() { }
}
