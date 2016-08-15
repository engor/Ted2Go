
// ***** alpha surface shader *****

varying vec2 TexCoord0;

//@vertex

void transform( out vec4 viewpos ){

	viewpos=mx2_ModelViewMatrix * mx2_VertexPosition;
	
	TexCoord0=mx2_VertexTexCoord0;
}

//@fragment

uniform sampler2D DiffuseTexture;

void lighting( out vec4 diffuse,out vec4 specular,out vec4 emissive,out vec3 normal,out float alpha ){

	emissive=vec4( texture2D( DiffuseTexture,TexCoord0 ).a );
	
	alpha=emissive.a;
}
