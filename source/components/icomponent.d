module components.icomponent;
import graphics.shaders.ishader;

interface IComponent
{
	void update();
	void draw( IShader shader );
	void shutdown();
}
