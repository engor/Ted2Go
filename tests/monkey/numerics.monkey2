
Namespace test

Function Main()

	Local x:ULong=$ffffffffffffffff	'Test signed/unsigned
	Print Byte( x )				'-1
	Print UByte( x )				'255
	Print Short( x )				'-1
	Print UShort( x )			'65535
	Print Int( x )				'-1
	Print UInt( x )				'4294967295
	Print Long( x )				'-1
	Print ULong( x )				'18446744073709551615

	Local y:UInt=$ffffffff		'Test Shr signed/unsigned...
	Print Int( y ) Shr 1			'-1
	Print UInt( y ) Shr 1		'2147483647
	
	Local a:UInt=$1000000		'Test 24 bit float precision...
	Print a						'16777216
	Print Float( a )				'16777216
	Print UInt( Float( a ) )		'16777216
	
	Local b:ULong=$20000000000000	'Test 53 bit double precision...
	Print b						'9007199254740992
	Print Double( b )			'9007199254740992
	Print ULong( Double( b ) )	'9007199254740992
	
End
