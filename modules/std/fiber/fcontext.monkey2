
#import "native/fcontext.cpp"
#import "native/fcontext.h"

#if __HOSTOS__="windows"
	#import "native/asm/make_i386_ms_pe_gas.asm"
	#import "native/asm/jump_i386_ms_pe_gas.asm"
	#import "native/asm/ontop_i386_ms_pe_gas.asm"
#else if __HOSTOS__="macos"
	#import "native/asm/make_x86_64_sysv_macho_gas.S"
	#import "native/asm/jump_x86_64_sysv_macho_gas.S"
	#import "native/asm/ontop_x86_64_sysv_macho_gas.S"
#else if __HOSTOS__="linux"
	#import "native/asm/make_x86_64_sysv_elf_gas.S"
	#import "native/asm/jump_x86_64_sysv_elf_gas.S"
	#import "native/asm/ontop_x86_64_sysv_elf_gas.S"
#end

'Testing purposes only - use Fiber instead!
'
'Will generally cause havoc on GC and debugger as they wont know you're messing with the stack...
'
Extern

Alias fcontext_t:Void Ptr

Struct transfer_t
	Field fcontext:fcontext_t
	Field data:Void Ptr
End

Function alloc_fcontext_stack:UByte Ptr( size:ULong )

Function free_fcontext_stack( stack:Void Ptr,size:ULong )

Function jump_fcontext:transfer_t( fcontext:fcontext_t,data:Void Ptr )

Function make_fcontext:fcontext_t( stack:Void Ptr,stack_size:ULong,func:Void( transfer_t ) )

Function ontop_fcontext:transfer_t( fcontext:fcontext_t,vp:Void ptr,func:transfer_t(transfer_t) )

Public

#rem
Function Test( t:transfer_t )

	Print "Test 1"
	Print ULong( t.fcontext )
	
	t=jump_fcontext( t.fcontext,Null )
	
	Print "Test 2"
	Print ULong( t.fcontext )
	
	jump_fcontext( t.fcontext,Null )
	
End

Function Test2( fcontext:fcontext_t )

	jump_fcontext( fcontext,Null )
	
End

Function Main()

	Local stack:=alloc_fcontext_stack( 65536 )
	
	Local fcontext:=make_fcontext( stack+65536,65536,Test )

	fcontext=jump_fcontext( fcontext,Null ).fcontext
	
	Test2( fcontext )
	
'	fcontext=jump_fcontext( fcontext,Null ).fcontext
	
	Return
	
	Print "Main"
	fcontext=jump_fcontext( fcontext,Null ).fcontext
	Print "Main"
	
	Test2( fcontext )

End
#end
