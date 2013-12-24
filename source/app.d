import core.dgame;
import scripting.scripts;

import myclass;

void main()
{
	Scripts.initialize();
	Scripts.callFunction!(MyClass)( getDGame.mangleof );

    new DGame().run();
}
