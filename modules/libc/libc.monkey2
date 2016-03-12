
Namespace libc

#Import "native/libc.cpp"
#Import "native/libc.h"

Extern

Struct size_t
End

Function sizeof<T>:Int( t:T )="(int)sizeof"

'***** stdio.h *****

Struct FILE
End

Const SEEK_SET:Int
Const SEEK_CUR:Int
Const SEEK_END:Int

Function fopen:FILE Ptr( path:CString,mode:CString )

Function rewind:Void( stream:FILE )
Function ftell:Int( stream:FILE Ptr )
Function fseek:Int( stream:FILE Ptr,offset:Int,whence:Int )

Function fread:Int( buf:Void Ptr,size:Int,count:Int,stream:FILE Ptr )
Function fwrite:Int( buf:Void Ptr,size:Int,count:Int,stream:FILE Ptr )
Function fclose:Int( stream:FILE Ptr )

Function remove:Int( path:CString )

'***** stdlib.h *****

Function malloc:Void Ptr( size:Int )
Function free:Void( mem:Void Ptr )

Function system:Int( cmd:CString )="system_"
Function setenv:Int( name:CString,value:CString,overwrite:Int )="setenv_"
Function getenv:CChar Ptr( name:CString )

Function exit_:Void( status:Int )="exit"
Function abort:Void()

'***** string.h *****

Function strlen:Int( str:CString )

Function memset:Void Ptr( dst:Void Ptr,value:Int,count:Int )
Function memcpy:Void Ptr( dst:Void Ptr,src:Void Ptr,length:Int )
Function memmove:Void Ptr( dst:Void Ptr,src:Void Ptr,length:Int )

'***** time.h *****

Alias time_t:Long

'***** unistd.h *****

Function getcwd:CChar Ptr( buf:CChar Ptr,size:Int )
Function chdir:Int( path:CString )
Function rmdir:Int( path:CString )

'***** sys/stat.h *****

Enum mode_t
End

Const S_IFMT:mode_t	'$f000
Const S_IFIFO:mode_t	'$1000
Const S_IFCHR:mode_t	'$2000
Const S_IFBLK:mode_t	'$3000
Const S_IFDIR:mode_t	'$4000
Const S_IFREG:mode_t	'$8000

Struct stat_t
	Field st_mode:mode_t
	Field st_atime:time_t	'last access
	Field st_mtime:time_t	'last modification
	Field st_ctime:time_t	'status change
End

Function stat:Int( path:CString,buf:stat_t Ptr )
Function mkdir:Int( path:CString,mode:Int )="mkdir_"

'***** dirent.h *****

Struct DIR
End

Struct dirent
	Field d_name:Void Ptr
End

Function opendir:DIR Ptr( path:CString )
Function readdir:dirent Ptr( dir:DIR Ptr )
Function closedir( dir:DIR Ptr )
