module graphics.adapters.adapter;
import core.global;

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

abstract class Adapter
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
