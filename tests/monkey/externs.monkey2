
Namespace test

#Import "externs.cpp"
#Import "externs.h"

Extern

Global G:Float

Function F()

Enum E
	E1
	E2
	E3
End

'alternate way to do 'c-style' enums...
Const E1:E="E::E1"
Const E2:E="E::E2"
Const E3:E="E::E3"

Class C

	Method New()
	
	Method New( d:D )
	
	Method E() Extension="glue_E"
	
End

Class D Extends C

	Method New()
	
	Method M()
	
	Method M2:Void Ptr( str:CString )
	
End

Class T Extends Void

	Method New()
	
	Method New( x:Int )
	
	Function Destroy( t:T )="delete"
	
End

Public

Function Main()

	Print Int( E.E1 )	'0
	Print Int( E.E2 )	'1
	Print Int( E.E3 )	'2

	F()					'::F()

	New C				'C::C()
	New C( New D )		'C::C(), D::D(), C::C( D* )
	New D				'D::D()
	
	Local s:=String.FromCString( New D().M2( "Hello!" ) )
	Print s				'Goodbye!
	
	New T				'T::T()
	New T( 10 )			'T::T( int )
	
	Local t:=New T		'T::T()
	
	T.Destroy( t )		'T::~T()
	
	New C().E()			'::glue_E()
End

