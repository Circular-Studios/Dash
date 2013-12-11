module graphics.windows.windowcontroller;

abstract class WindowController
{
public:
	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void messageLoop();

	abstract void openWindow();
	abstract void closeWindow();
}
