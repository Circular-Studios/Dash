module graphics.adapters.adapter;
import core.global;
import graphics.adapters.opengl;

union DeviceContext
{
	GLDeviceContext gl;
	void* dx;
}

union Device
{
	void* gl;
	void* dx;
}

abstract class Adapter
{
public:
	abstract void initialize();
	abstract void shutdown();
	abstract void resize();
	abstract void reload();

	abstract void beginDraw();
	abstract void endDraw();

	mixin( Property!( "Device", "device", "protected" ) );
	mixin( Property!( "DeviceContext", "deviceContext", "protected" ) );

private:

}
