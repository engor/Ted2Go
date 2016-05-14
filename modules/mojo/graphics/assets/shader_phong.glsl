
// ***** phong surface shader *****

varying vec2 texCoord0;

//@vertex

void transform( out vec4 viewpos ){

	viewpos=mx2_ModelViewMatrix * mx2_Vertex;

	texCoord0=mx2_TexCoord0;
}

//@fragment

uniform sampler2D ColorTexture;			//default=white
uniform sampler2D SpecularTexture;		//default=white
uniform sampler2D NormalTexture;		//default=smooth

void ambientPass( out vec4 ambient ){

	diffuse=texture2D( ColorTexture,texCoord0 ) * mx2_Color * mx2_AmbientLight;
}

void lightingPass( out vec4 diffuse,out vec4 specular,out vec4 normal ){

	diffuse=texture2D( ColorTexture,texCoord0 ) * mx2_Color;
	
	specular=texture2D( SpecularTexture,texCoord0 );
	
	normal=normalize( mat3( mx2_ModelViewMatrix ) * texture2D( NormalTexture,texCoord0 ).xyz );
}
