
// ***** phong surface shader *****

varying vec2 TexCoord0;

//@vertex

void transform( out vec4 viewpos ){

	viewpos=mx2_ModelViewMatrix * mx2_VertexPosition;
	
	TexCoord0=mx2_VertexTexCoord0;
}

//@fragment

uniform sampler2D DiffuseTexture;
uniform sampler2D SpecularTexture;
uniform sampler2D NormalTexture;

void lighting( out vec4 diffuse,out vec4 specular,out vec4 emissive,out vec3 normal,out float alpha ){

	diffuse=texture2D( DiffuseTexture,TexCoord0 );
	
	specular=texture2D( SpecularTexture,TexCoord0 );
	
	normal=normalize( mat3( mx2_ModelViewMatrix ) * texture2D( NormalTexture,TexCoord0 ).xyz );
	
	alpha=diffuse.a;
}
