module graphics.shaders.ishader;
import components.texture, components.mesh;
import math.matrix;

abstract class IShader
{
public:
	void bindTexture( Texture texture );
	void drawMesh( Mesh mesh );

	void shutdown();

	Matrix!4 projectionMatrix, viewMatrix, modelMatrix;
}
