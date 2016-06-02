
// One of these defined!

//#define RENDERPASS_AMBIENT

//#define RENDERPASS_NORMAL

//#define RENDERPASS_LIGHT

uniform mat4 mx2_ModelViewMatrix;
uniform mat4 mx2_ProjectionMatrix;
uniform vec4 mx2_AmbientLight;
uniform vec4 mx2_RenderColor;

varying vec4 mx2_ViewPosition;
varying vec4 mx2_Color;

#if defined( RENDERPASS_LIGHT )
varying vec2 mx2_FragPos;
#endif

//@vertex

attribute vec4 mx2_VertexPosition;
attribute vec2 mx2_VertexTexCoord0;
attribute vec2 mx2_VertexTangent;
attribute vec4 mx2_VertexColor;

void transform( out vec4 viewpos );

void main(){

	vec4 position;
	
	transform( position );
	
	mx2_ViewPosition=position;
	mx2_Color=mx2_RenderColor * mx2_VertexColor;
	
	gl_Position=mx2_ProjectionMatrix * position;
	
#if defined( RENDERPASS_LIGHT )
	mx2_FragPos=gl_Position;
#endif
}

//@fragment

#if defined( RENDERPASS_LIGHT )

uniform vec4 mx2_LightVector;
uniform vec4 mx2_LightColor;
uniform sampler2D mx2_NormalTexture;

#endif

void lighting( out vec4 diffuse,out vec4 specular,out vec4 emissive,out vec3 normal,out float alpha );

void main(){

	vec4 diffuse,specular,emissive;
	vec3 normal;
	float alpha;
	
	lighting( diffuse,specular,emissive,normal,alpha );

#if defined( RENDERPASS_AMBIENT )

	vec4 color=diffuse * mx2_AmbientLight + emissive;
	
	gl_FragColor=vec4( color.rgb,alpha ) * mx2_Color;
	
#elif defined( RENDERPASS_NORMAL )

	//write out normal + specular component
	//
	gl_FragColor=vec4( normal * alpha,specular.w );
	
#elif defined( RENDERPASS_LIGHT )

	vec4 npass=texture2D( mx2_PassTexture,mx2_FragPos );
	
	//grab normal
	vec3 normal=npass.xyz;

	//specular power
	float gloss=npass.w;
	float spow=pow( 2.0,gloss*12.0 );
	float fnorm=(spow+8.0)/25.1327412287;		//	(n+8)/8*pi apparently for blinn-phong...

	//normalized vector to eye	
	
	vec3 v=mx2_LightVector.xyz-mx2_ViewPosition.xyz;
	float falloff=max( 1.0-length( v )/mx2_LightVector.w,0.0 );
	
	vec3 lvec=normalize( v );
	vec3 evec=normalize( -mx2_ViewPosition.xyz );
	vec3 hvec=normalize( lvec + evec );
	
	float ndotv=max( dot( normal,evec ),0.0 );
	float ndotl=max( dot( normal,lvec ),0.0 );
	float ndoth=max( dot( normal,hvec ),0.0 );
	
	float i=ndtol * falloff;
	
	vec3 diff=mx2_LightColor.rgb * i;
	float spec=mx2_LightColor.w * i * pow( ndoth,spow ) * fnorm;
	
	//frenel-ish?
	spec+=(1.0-spec) * pow( 1.0-ndotv,5.0 ) * gloss;
	
	//write diffuse + specular
	gl_FragColor=vec4( diff,spec );
	
#elif defined( RENDERPASS_LIGHT2 )

	vec4 intex=texture2D( mx2_PassTexture,mx2_FragPos );
	
	diffuse=diffuse * mx2_AmbientLight + (diffuse * intex.rgb) + emissive;
	
	specular=specular * intex.w;
	
	gl_FragColor=vec4( (diffuse+specular).rgb,alpha );
	
#endif

}
