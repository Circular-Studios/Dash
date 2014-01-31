module graphics.shaders.glshader;
import core.properties;
import components.mesh, components.texture;
import graphics.shaders.shader;
import utility.filepath, utility.output;
import derelict.opengl3.gl3;

package class GLShader : Shader
{
public:
	mixin Property!( "uint", "programID", "protected" );
	mixin Property!( "uint", "vertexShaderID", "protected" );
	mixin Property!( "uint", "fragmentShaderID", "protected" );

	this( string vertexPath, string fragmentPath )
	{
		// Create shader
        vertexShaderID = glCreateShader( GL_VERTEX_SHADER );
        fragmentShaderID = glCreateShader( GL_FRAGMENT_SHADER );
        programID = glCreateProgram();

		auto vertexFile = new FilePath( vertexPath );
		auto fragmentFile = new FilePath( fragmentPath );
		string vertexBody = vertexFile.getContents();
		string fragmentBody = fragmentFile.getContents();
		auto vertexCBody = vertexBody.ptr;
		auto fragmentCBody = fragmentBody.ptr;
		int vertexSize = vertexBody.length;
		int fragmentSize = fragmentBody.length;

		glShaderSource( vertexShaderID, 1, &vertexCBody, &vertexSize );
		glShaderSource( fragmentShaderID, 1, &fragmentCBody, &fragmentSize );

		GLint compileStatus = GL_TRUE;
		glCompileShader( vertexShaderID );
		glGetShaderiv( vertexShaderID, GL_COMPILE_STATUS, &compileStatus );
		if( compileStatus != GL_TRUE )
		{
			log( OutputType.Error, "Vertex Shader compile error" );
			char[1000] errorLog;
			auto info = errorLog.ptr;
			glGetShaderInfoLog( vertexShaderID, 1000, null, info );
			log( OutputType.Error, errorLog );
			assert(false);
		}

		glCompileShader( fragmentShaderID );
		glGetShaderiv( fragmentShaderID, GL_COMPILE_STATUS, &compileStatus );
		if( compileStatus != GL_TRUE )
		{
			log( OutputType.Error, "Fragment Shader compile error" );
			assert(false);
		}

		// Attach shaders to program
        glAttachShader( programID, vertexShaderID );
        glAttachShader( programID, fragmentShaderID );
		glLinkProgram( programID );

		glGetProgramiv( programID, GL_LINK_STATUS, &compileStatus );
        if( compileStatus != GL_TRUE )
        {
			log( OutputType.Error, "Shader program linking error" );
			assert(false);
		}
	}

	override void shutdown()
	{

	}
}
