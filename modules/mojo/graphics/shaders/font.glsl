
//@renderpasses 0,1,2

varying vec2 texCoord0;
varying vec4 color;

//@vertex

attribute vec4 mx2_Vertex;
attribute vec2 mx2_TexCoord0;
attribute vec4 mx2_Color;

uniform mat4 mx2_ModelViewProjectionMatrix;

uniform vec4 mx2_ImageColor;

void main(){

	texCoord0=mx2_TexCoord0;

	color=mx2_ImageColor * mx2_Color;
	
	gl_Position=mx2_ModelViewProjectionMatrix * mx2_Vertex;
}

//@fragment

uniform sampler2D mx2_ImageTexture0;

void main(){

	float alpha=texture2D( mx2_ImageTexture0,texCoord0 ).a;

#if MX2_RENDERPASS==0

	gl_FragColor=vec4( alpha ) * color;

#else

	gl_FragColor=vec4( 0.0,0.0,0.0,alpha * color.a );
	
#endif

}
