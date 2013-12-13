module graphics.shaders.ishader;
import components.texture, components.mesh;

interface IShader
{
	void bindTexture( Texture texture );
	void drawMesh( Mesh mesh );
}
