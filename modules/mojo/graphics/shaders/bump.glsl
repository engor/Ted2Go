
//@renderpasses 0,1,2

varying vec2 texCoord0;
varying mat2 tanMatrix;
varying vec4 color;

//@vertex

attribute vec4 mx2_Vertex;
attribute vec2 mx2_TexCoord0;
attribute vec2 mx2_TexCoord1;
attribute vec4 mx2_Color;

uniform mat4 mx2_ModelViewProjectionMatrix;

uniform vec4 mx2_AmbientLight;

uniform vec4 mx2_ImageColor;

void main(){

	texCoord0=mx2_TexCoord0;

	tanMatrix=mat2( mx2_TexCoord1.x,mx2_TexCoord1.y,-mx2_TexCoord1.y,mx2_TexCoord1.x );

#if MX2_RENDERPASS==0
	color=mx2_AmbientLight * mx2_ImageColor * mx2_Color;
#else
	color=mx2_ImageColor * mx2_Color;
#endif
	
	gl_Position=mx2_ModelViewProjectionMatrix * mx2_Vertex;
}

//@fragment

uniform sampler2D mx2_ImageTexture0;

uniform sampler2D mx2_ImageTexture1;

void main(){

	vec4 diffuse=texture2D( mx2_ImageTexture0,texCoord0 ) * color;

#if MX2_RENDERPASS==0		//ambient

	gl_FragColor=diffuse;

#elif MX2_RENDERPASS==1		//diffuse

	gl_FragColor=diffuse;
	
#elif MX2_RENDERPASS==2		//normal

	vec3 normal=texture2D( mx2_ImageTexture1,texCoord0 ).xyz;
	
	normal.xy=tanMatrix * (normal.xy * 2.0 - 1.0) * diffuse.a * 0.5 + 0.5;
	normal.z*=diffuse.a;
	
	gl_FragColor=vec4( normal,diffuse.a );

#endif

}
