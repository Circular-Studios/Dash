module graphics.windows.windows;
import core.global;

abstract class Windows
{
public:
	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void messageLoop();

	abstract void openWindow();
	abstract void closeWindow();

protected:
	uint width, screenWidth;
	uint height, screenHeight;
	bool fullscreen;
}
