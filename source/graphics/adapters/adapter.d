module graphics.adapters.adapter;
import core.properties;
import graphics.adapters.opengl;

abstract class Adapter
{
public:
	mixin BackedProperty!( "void*", "_glDevice", "glDevice", "protected" );
	mixin BackedProperty!( "void*", "_dxDevice", "dxDevice", "protected" );
	mixin BackedProperty!( "GLDeviceContext", "_glDeviceContext", "glDeviceContext", "protected" );
	mixin BackedProperty!( "void*", "_dxDeviceContext", "dxDeviceContext", "protected" );
	mixin BackedProperty!( "GLRenderContext", "_glRenderContext", "glRenderContext", "protected" );
	mixin BackedProperty!( "void*", "_dxRenderContext", "dxRenderContext", "protected" );

	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();

	abstract void beginDraw();
	abstract void endDraw();

private:
	union
	{
		void* _glDevice;
		void* _dxDevice;
	}

	union
	{
		GLDeviceContext _glDeviceContext;
		void* _dxDeviceContext;
	}

	union
	{
		GLRenderContext _glRenderContext;
		void* _dxRenderContext;
	}
}
