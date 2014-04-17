/**
* Shader to output depth for a shadowmap
*/
module graphics.shaders.glsl.shadowmap;

package:

/// Vertex Shader
immutable string shadowmapVS = q{
    #version 400

    layout(location = 0) in vec3 vPosition_m;

    uniform mat4 worldViewProjection;

    void main()
    {
        gl_Position = worldViewProj * vec4( vPosition_m, 1.0f );
    }

};

/// Fragment Shader, just output depth
immutable string shadowmapFS = q{
    #version 400

    layout(location = 0) out float fragDepth;

    void main()
    {
        fragDepth = gl_FragCoord.z;
    }

};