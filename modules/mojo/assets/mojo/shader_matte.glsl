
// ***** matte surface shader *****

varying vec2 texCoord0;

//@vertex

void transform( out vec4 viewpos ){

	viewpos=mx2_ModelViewMatrix * mx2_Vertex;

	texCoord0=mx2_TexCoord0;
}

//@fragment

uniform sampler2D ColorTexture;		//default=white
uniform sampler2D SpecularTexture;	//default=black
uniform sampler2D NormalTexture;	//default=black

void ambientPass( out vec4 ambient ){
	
	ambient=texture2D( ColorTexture,texCoord0 ) * mx2_AmbientLight;
}

void lightingPass( out vec4 diffuse,out vec4 specular,out vec4 normal ){

}
