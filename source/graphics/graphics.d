module graphics.graphics;
import graphics.adapters.adapter, graphics.adapters.opengl, graphics.adapters.directx;
import graphics.windows.windows, graphics.windows.win32;

class Graphics
{
static
{
public:
	@property Adapter adapter()
	{
		// if gl
		{
			if( gl is null )
				gl = new OpenGL();
			return gl;
		}
		// elseif dx
		{
			if( dx is null )
				dx = new DirectX();
			return dx;
		}
	}

	@property Windows window()
	{
		// if win32
		version( Windows )
		{
			if( win is null )
				win = new Win32();
			return win;
		}
	}

	void initialize()
	{
		adapter.initialize();
		//Shaders.initialize();
	}

private:
	OpenGL gl;
	DirectX dx;

	Windows win;
}
}
