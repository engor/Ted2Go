
// ***** ambient shaderenv *****

uniform mat4 mx2_ModelViewMatrix;
uniform mat4 mx2_ProjectionMatrix;
uniform vec4 mx2_AmbientLight;
uniform vec4 mx2_RenderColor;

varying vec4 mx2_Color;

//@vertex

attribute vec4 mx2_Vertex;
attribute vec2 mx2_TexCoord0;
attribute vec2 mx2_Tangent;
attribute vec4 mx2_VertexColor;

void transform( out vec4 viewpos );

void main(){
	vec4 position;
	transform( position );
	gl_Position=mx2_ProjectionMatrix * position;
	mx2_color=mx2_VertexColor * mx2_RenderColor;
}

//@fragment

void lightingPass( out vec4 diffuse,out vec4 specular,out vec3 normal );

void main(){

	vec4 diffuse,specular;
	vec3 normal;
	
	lightingPass( ambient,diffuse,specular,normal );
}
