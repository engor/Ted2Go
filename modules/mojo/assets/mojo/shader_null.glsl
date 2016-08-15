
// ***** alpha surface shader *****

//@vertex

void transform( out vec4 viewpos ){

	viewpos=mx2_ModelViewMatrix * mx2_VertexPosition;

	gl_PointSize=1.0;
}

//@fragment

void lighting( out vec4 diffuse,out vec4 specular,out vec4 emissive,out vec3 normal,out float alpha ){

	emissive=vec4( 1.0 );
	
	alpha=1.0;
}
