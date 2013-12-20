module graphics.adapters.adapter;
import core.properties;
import graphics.adapters.opengl;

abstract class Adapter
{
public:
	@property void* glDevice() { return _glDevice; }
	@property void* dxDevice() { return _dxDevice; }
	@property GLDeviceContext glDeviceContext() { return _glDeviceContext; }
	@property void* dxDeviceContext() { return _dxDeviceContext; }

	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();

	abstract void beginDraw();
	abstract void endDraw();

protected:
	@property void glDevice( void* val ) { _glDevice = val; }
	@property void dxDevice( void* val ) { _dxDevice = val; }
	@property void glDeviceContext( GLDeviceContext val ) { _glDeviceContext = val; }
	@property void dxDeviceContext( void* val ) { _dxDeviceContext = val; }

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
}
