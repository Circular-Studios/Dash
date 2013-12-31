module graphics.windows.windows;
import core.properties;
import graphics.adapters.opengl;

abstract class Windows
{
public:
	mixin Property!( "uint", "width", "protected" );
	mixin Property!( "uint", "screenWidth", "protected" );
	mixin Property!( "uint", "height", "protected" );
	mixin Property!( "uint", "screenHeight", "protected" );
	mixin Property!( "bool", "fullscreen", "protected" );

	abstract @property OpenGL gl();

	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void messageLoop();

	abstract void openWindow();
	abstract void closeWindow();
}
