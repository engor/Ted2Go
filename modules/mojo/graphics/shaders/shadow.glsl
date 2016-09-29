
//@renderpasses 4

//@vertex

attribute vec4 mx2_Vertex;

uniform mat4 mx2_ModelViewProjectionMatrix;

void main(){

	gl_Position=mx2_ModelViewProjectionMatrix * mx2_Vertex;
}

//@fragment

void main(){

	gl_FragColor=vec4( 1.0,1.0,1.0,0.0 );
}
