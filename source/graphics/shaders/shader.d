module graphics.shaders.shader;
import components.texture, components.mesh;
import math.matrix;

abstract class Shader
{
public:
	void bindTexture( Texture texture );
	void drawMesh( Mesh mesh );

	void shutdown();

	Matrix!4 projectionMatrix, viewMatrix, modelMatrix;
}
