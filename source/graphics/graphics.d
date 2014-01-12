module graphics.graphics;
import core.properties;
import graphics.adapters, graphics.windows, graphics.shaders.shaders;
import utility.config;

enum GraphicsAdapter { OpenGL, DirectX };

static class Graphics
{
static:
public:
	/**
	 * The currently active adapter type.
	 */
	mixin Property!( "GraphicsAdapter", "activeAdapter" );

	/**
	 * A pointer to the currently active adapter.
	 */
	@property Adapter adapter()
	{
		if( activeAdapter == GraphicsAdapter.OpenGL )
		{
			return window.gl;
		}
		version( Windows )
		{
			static DirectX dx;
			if( activeAdapter == GraphicsAdapter.DirectX )
			{
				if( dx is null )
					dx = new DirectX();
				return dx;
			}
		}

		return null;
	}

	/**
	 * A pointer to the currently active window manager.
	 */
	@property Windows window()
	{
		// if win32
		version( Windows )
		{
			static Windows win;
			if( win is null )
				win = new Win32;
			return win;
		}
		else version( OSX )
		{
			static MacX11 x11;
			if( x11 is null )
				x11 = new MacX11;
			return x11;
		}
		else
		{
			return null;
		}
	}

	/**
	 * Initialize the controllers.
	 */
	void initialize()
	{
		activeAdapter = Config.get!GraphicsAdapter( "Graphics.Adapter" );
		adapter.initialize();
		Shaders.initialize();
	}

	/**
	 * Shutdown the adapter and shaders.
	 */
	void shutdown()
	{
		Shaders.shutdown();
		adapter.shutdown();
	}
}
