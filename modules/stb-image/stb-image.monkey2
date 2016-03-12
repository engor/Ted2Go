
Namespace stb.image

#Import "native/stb_image.c"
#Import "native/stb_image.h"

Extern

Struct stbi_char="char"
End

Struct stbi_io_callbacks
	Field read:Int( Void Ptr,stbi_char Ptr,Int )
	Field skip:Void( Void Ptr,Int )
	Field eof:Int( Void Ptr )
End

Function stbi_load:UByte Ptr( filename:String,x:Int Ptr,y:Int Ptr,comp:Int Ptr,req_comp:Int )
Function stbi_load_from_memory:UByte Ptr( buffer:UByte Ptr,x:Int Ptr,y:Int Ptr,comp:Int Ptr,req_comp:Int )
Function stbi_load_from_callbacks:UByte Ptr( clbk:stbi_io_callbacks Ptr,user:Void Ptr,x:Int Ptr,y:Int Ptr,comp:Int Ptr,req_comp:Int )
