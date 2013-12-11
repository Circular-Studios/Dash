module graphics.graphicscontroller;
import graphics.adapters.adaptercontroller, graphics.adapters.openglcontroller, graphics.adapters.directxcontroller;
import graphics.windows.windowcontroller, graphics.windows.win32controller;

class GraphicsController
{
static
{
public:
	@property AdapterController adapter()
	{
		// if gl
		{
			if( gl is null )
				gl = new OpenGLController();
			return gl;
		}
		// elseif dx
		{
			if( dx is null )
				dx = new DirectXController();
			return dx;
		}
	}

	@property WindowController window()
	{
		// if win32
		version( Windows )
		{
			if( win is null )
				win = new Win32Controller();
			return win;
		}
	}

private:
	OpenGLController gl;
	DirectXController dx;

	Win32Controller win;
}
}
