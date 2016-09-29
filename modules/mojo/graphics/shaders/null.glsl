
//@renderpasses 0

varying vec4 color;

//@vertex

attribute vec4 mx2_Vertex;
attribute vec4 mx2_Color;

uniform mat4 mx2_ModelViewProjectionMatrix;

void main(){

	color=mx2_Color;
	
	gl_Position=mx2_ModelViewProjectionMatrix * mx2_Vertex;
	
	gl_PointSize=1.0;
}

//@fragment

void main(){

	gl_FragColor=color;
}
