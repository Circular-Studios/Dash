module graphics.adapters.adaptercontroller;
import core.graphosglobal;

union DeviceContext
{
	void* gl;
	void* dx;
}

union Device
{
	void* gl;
	void* dx;
}

abstract class AdapterController
{
public:
	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();

	abstract void beginDraw();
	abstract void endDraw();

	mixin( Property!( "Device", "device" ) );
	mixin( Property!( "DeviceContext", "deviceContext" ) );

private:
}
