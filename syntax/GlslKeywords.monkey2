
Namespace ted2go


Class GlslKeywords Extends KeywordsPlugin
	
	Property Name:String() Override
		Return "GlslKeywords"
	End
	
	
	Private
	
	Global _instance:=New GlslKeywords
	
	Method New()
		Super.New()
		_types=New String[]( ".glsl" )
	End
	
	Method GetInternal:String() Override
		Local s:="attribute;const;uniform;varying;layout;centroid;flat;smooth;noperspective;break;continue;do;for;while;switch;case;default;if;else;in;out;inout;float;int;void;bool;true;false;invariant;discard;return;mat2;mat3;mat4;mat2x2;mat2x3;mat2x4;mat3x2;mat3x3;mat3x4;mat4x2;mat4x3;mat4x4;vec2;vec3;vec4;ivec2;ivec3;ivec4;bvec2;bvec3;bvec4;uint;uvec2;uvec3;uvec4;lowp;mediump;highp;precision;sampler1D;sampler2D;sampler3D;samplerCube;sampler1DShadow;sampler2DShadow;samplerCubeShadow;sampler1DArray;sampler2DArray;sampler1DArrayShadow;sampler2DArrayShadow;isampler1D;isampler2D;isampler3D;isamplerCube;isampler1DArray;isampler2DArray;usampler1D;usampler2D;usampler3D;usamplerCube;usampler1DArray;usampler2DArray;sampler2DRect;sampler2DRectShadow;isampler2DRect;usampler2DRect;samplerBuffer;isamplerBuffer;usamplerBuffer;sampler2DMS;isampler2DMS;usampler2DMS;sampler2DMSArray;isampler2DMSArray;usampler2DMSArray;struct;radians;degrees;sin;cos;tan;asin;acos;atan;atan;sinh;cosh;tanh;asinh;acosh;atanh;pow;exp;log;exp2;log2;sqrt;inversesqrt;abs;sign;floor;trunc;round;roundEven;ceil;fract;mod;modf;min;max;clamp;mix;step;smoothstep;isnan;isinf;floatBitsToInt;floatBitsToUint;intBitsToFloat;uintBitsToFloat;length;distance;dot;cross;normalize;faceforward;reflect;refract;matrixCompMult;outerProduct;transpose;determinant;inverse;lessThan;lessThanEqual;greaterThan;greaterThanEqual;equal;notEqual;any;all;not;textureSize;texture;textureProj;textureLod;textureOffset;texelFetch;texelFetchOffset;textureProjOffset;textureLodOffset;textureProjLod;textureProjLodOffset;textureGrad;textureGradOffset;textureProjGrad;textureProjGradOffset;texture1D;texture1DProj;texture1DProjLod;texture2D;texture2DProj;texture2DLod;texture2DProjLod;texture3D;texture3DProj;texture3DLod;texture3DProjLod;textureCube;textureCubeLod;shadow1D;shadow2D;shadow1DProj;shadow2DProj;shadow1DLod;shadow2DLod;shadow1DProjLod;shadow2DProjLod;dFdx;dFdy;fwidth;noise1;noise2;noise3;noise4;EmitVertex;EndPrimitive;gl_VertexID;gl_InstanceID;gl_Position;gl_PointSize;gl_ClipDistance;gl_PerVertex;gl_Layer;gl_ClipVertex;gl_FragCoord;gl_FrontFacing;gl_ClipDistance;gl_FragColor;gl_FragData;gl_MaxDrawBuffers;gl_FragDepth;gl_PointCoord;gl_PrimitiveID;gl_MaxVertexAttribs;gl_MaxVertexUniformComponents;gl_MaxVaryingFloats;gl_MaxVaryingComponents;gl_MaxVertexOutputComponents;gl_MaxGeometryInputComponents;gl_MaxGeometryOutputComponents;gl_MaxFragmentInputComponents;gl_MaxVertexTextureImageUnits;gl_MaxCombinedTextureImageUnits;gl_MaxTextureImageUnits;gl_MaxFragmentUniformComponents;gl_MaxDrawBuffers;gl_MaxClipDistances;gl_MaxGeometryTextureImageUnits;gl_MaxGeometryOutputVertices;gl_MaxGeometryOutputVertices;gl_MaxGeometryTotalOutputComponents;gl_MaxGeometryUniformComponents;gl_MaxGeometryVaryingComponents;gl_DepthRange"
		Return s
	End
	
End