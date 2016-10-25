
Namespace libc

#Import "native/libc.cpp"
#Import "native/libc.h"

Extern

#rem monkeydoc C/C++ 'char' type.
#end
Struct char_t="char"
End

#rem monkeydoc C/C++ 'const char' type.
#end
Struct const_char_t="const char"
End

#rem monkeydoc C/C++ 'signed char' type.
#end
Struct signed_char_t="signed char"
End

#rem monkeydoc C/C++ 'unsigned char' type
#end
Struct unsigned_char_t="unsigned char"
End

#rem monkeydoc C/C++ 'wchar_t' type
#end
Struct wchar_t="wchar_t"
End

#rem monkeydoc C/C++ 'size_t' type
#end
Struct size_t="size_t"
End

Function sizeof<T>:Int( t:T )="(int)sizeof"

'***** stdio.h *****

Struct FILE
End

Const stdin:FILE Ptr
Const stdout:FILE Ptr
Const stderr:FILE Ptr

Const SEEK_SET:Int
Const SEEK_CUR:Int
Const SEEK_END:Int

Function fopen:FILE Ptr( path:CString,mode:CString )

Function rewind:Void( stream:FILE )
Function ftell:Int( stream:FILE Ptr )
Function fseek:Int( stream:FILE Ptr,offset:Int,whence:Int )

Function fread:Int( buf:Void Ptr,size:Int,count:Int,stream:FILE Ptr )
Function fwrite:Int( buf:Void Ptr,size:Int,count:Int,stream:FILE Ptr )
Function fflush:Int( stream:FILE Ptr )
Function fclose:Int( stream:FILE Ptr )
Function fputs:Int( str:CString,stream:FILE Ptr )

Function remove:Int( path:CString )
Function rename:Int( oldPath:CString,newPath:CString )

Function puts:Int( str:CString )

'***** stdlib.h *****

Function malloc:Void Ptr( size:Int )
Function free:Void( mem:Void Ptr )

Function system:Int( cmd:CString )="system_"
Function setenv:Int( name:CString,value:CString,overwrite:Int )="setenv_"
Function getenv:char_t Ptr( name:CString )

Function exit_:Void( status:Int )="exit"
Function atexit:Int( func:Void() )="atexit" 
Function abort:Void()

'***** string.h *****

Function strlen:Int( str:CString )

Function memset:Void Ptr( dst:Void Ptr,value:Int,count:Int )
Function memcpy:Void Ptr( dst:Void Ptr,src:Void Ptr,length:Int )
Function memmove:Void Ptr( dst:Void Ptr,src:Void Ptr,length:Int )
Function memcmp:Int( dst:Void Ptr,src:Void Ptr,length:Int )

'***** time.h *****

Struct time_t
End

Struct tm_t
	Field tm_sec:Int
	Field tm_min:Int
	Field tm_hour:Int
	Field tm_mday:Int
	Field tm_mon:Int
	Field tm_year:Int
	Field tm_wday:Int
	Field tm_yday:Int
	Field tm_isdst:Int
End

Struct timeval
	Field tv_sec:Long	'dodgy - should be time_t
	Field tv_usec:Long	'dodyy - should be suseconds_t
End

Struct timezone
End

'Note: clock() scary - pauses while process sleeps!
Const CLOCKS_PER_SEC:Long="((bbLong)CLOCKS_PER_SEC)"
Function clock:Long()="(bbLong)clock"

Function tolong:Long( timer:time_t )="bbLong"

Function time:time_t( timer:time_t Ptr )
Function localtime:tm_t Ptr( timer:time_t Ptr )
Function gmtime:tm_t Ptr( timer:time_t Ptr )
Function difftime:Double( endtime:time_t,starttime:time_t ) 
Function gettimeofday:Int( tv:timeval Ptr )="gettimeofday_"

'***** unistd.h *****

Function getcwd:char_t Ptr( buf:char_t Ptr,size:Int )
Function chdir:Int( path:CString )
Function rmdir:Int( path:CString )

'***** sys/stat.h *****

Enum mode_t
End

Const S_IFMT:mode_t		'$f000
Const S_IFIFO:mode_t	'$1000
Const S_IFCHR:mode_t	'$2000
Const S_IFBLK:mode_t	'$3000
Const S_IFDIR:mode_t	'$4000
Const S_IFREG:mode_t	'$8000

Struct stat_t
	Field st_mode:mode_t
	Field st_size:Long
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
