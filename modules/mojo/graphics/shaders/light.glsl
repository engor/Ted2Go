
//@renderpasses 4,5

varying vec2 texCoord0;
varying vec2 lightPos;
varying vec4 color;

varying vec2 gbufferCoords;
varying vec2 fragPos;

//@vertex

attribute vec4 mx2_Vertex;
attribute vec2 mx2_TexCoord0;
attribute vec2 mx2_TexCoord1;
attribute vec4 mx2_Color;

uniform mat4 mx2_ModelViewProjectionMatrix;

uniform vec2 mx2_ViewportOrigin;
uniform vec2 mx2_ViewportSize;
uniform vec2 mx2_ViewportClip;

uniform vec2 mx2_GBufferScale;

uniform vec4 mx2_ImageColor;

void main(){

	texCoord0=mx2_TexCoord0;
	lightPos=mx2_TexCoord1;
	color=mx2_ImageColor * mx2_Color;

	gl_Position=mx2_ModelViewProjectionMatrix * mx2_Vertex;
	
	vec2 vpcoords=(gl_Position.xy * 0.5 + 0.5) * mx2_ViewportSize;
	
	gbufferCoords=(vpcoords + mx2_ViewportOrigin) * mx2_GBufferScale;

	fragPos=vpcoords;
	fragPos.y=mx2_ViewportSize.y-fragPos.y;
	fragPos-=mx2_ViewportClip;
}

//@fragment

uniform sampler2D mx2_ImageTexture0;			//image texture
uniform float mx2_LightDepth;

uniform sampler2D mx2_GBuffer0;					//gbuffer diffuse
uniform sampler2D mx2_GBuffer1;					//gbuffer normal

void main(){

	vec3 normal=texture2D( mx2_GBuffer1,gbufferCoords ).xyz;
	
	float gloss=normal.z;
	
	normal.xy=normal.xy * 2.0 - 1.0;
	
	normal.z=sqrt( 1.0-dot( normal.xy,normal.xy ) );
	
	//diffuse...
	//	
	vec3 lvec=normalize( vec3( lightPos-fragPos,mx2_LightDepth ) );
	
	float ndotl=max( dot( normal,lvec ),0.0 );
	
	vec4 tcolor=texture2D( mx2_ImageTexture0,texCoord0 ) * color;

	vec4 diffuse=texture2D( mx2_GBuffer0,gbufferCoords ) * tcolor * ndotl;
	
	//specular...
	//
	vec3 hvec=normalize( lvec+vec3( 0.0,0.0,1.0 ) );
	
	float ndoth=max( dot( normal,hvec ),0.0 );
	
	vec4 specular=tcolor * pow( ndoth,128.0 ) * gloss;
	
#if MX2_RENDERPASS==5

	float shadow=texture2D( mx2_GBuffer0,gbufferCoords ).a;
	diffuse*=shadow;
	specular*=shadow;

#endif
	
	//tada!
	//
	gl_FragColor=vec4( diffuse.rgb+vec3( specular.a ),0.0 );
}
