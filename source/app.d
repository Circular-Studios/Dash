module app;
import core.dgame;

void main()
{
	if( !mainGame )
		mainGame = new DGame;

	mainGame.run();
}
