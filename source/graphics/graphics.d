module graphics.graphics;
import core.global;
import graphics.adapters, graphics.windows;

enum GraphicsAdapter { OpenGL, DirectX };

static class Graphics
{
static:
public:
	mixin( Property!( "GraphicsAdapter", "activeAdapter" ) );

	@property Adapter adapter()
	{
		static OpenGL gl;
		static DirectX dx;

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
			static Windows win;
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
}
