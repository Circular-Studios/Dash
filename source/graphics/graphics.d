module graphics.graphics;
import core.global;
import graphics.adapters.adapter, graphics.adapters.opengl, graphics.adapters.directx;
import graphics.windows.windows, graphics.windows.win32;

enum GraphicsAdapter { OpenGL, DirectX };

class Graphics
{
static
{
public:
	mixin( Property!( "GraphicsAdapter", "activeAdapter", "private", "" ) );

	@property Adapter adapter()
	{
		if( activeAdapter == GraphicsAdapter.OpenGL )
		{
			if( gl is null )
				gl = new OpenGL();
			return gl;
		}
		if( activeAdapter == GraphicsAdapter.DirectX )
		{
			if( dx is null )
				dx = new DirectX();
			return dx;
		}

		return null;
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
		activeAdapter = GraphicsAdapter.OpenGL;
		adapter.initialize();
		//Shaders.initialize();
	}

private:
	OpenGL gl;
	DirectX dx;

	Windows win;
}
}
