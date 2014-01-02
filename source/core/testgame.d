module core.testgame;
import core.dgame;
import utility.output;

@Game!TestGame class TestGame : DGame
{
	override void initialize()
	{
		Output.printMessage( OutputType.Info, "Initializing..." );
	}
	override void update() { }
	override void draw()	{ }
	override void shutdown() { }
}
