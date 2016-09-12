
#import "<std>"

Using std..

Class UniformBuffer

	Method Id<T>( name:String )
	
		Return Values<T>.Get( Self ).Id( name )
	End

	Method Set<T>( name:String,value:T )
	
		Values<T>.Get( Self ).Set( name,value )
	End
	
	Method Clear<T>( name:String )
	
		Values<T>.Get( Self ).Clear( name )
	End
	
	Method Exists<T>:Bool( name:String )
	
		Return Values<T>.Get( Self ).Exists( name )
	End
	
	Method Get<T>:T( name:String )
	
		Return Values<T>.Get( Self ).Get( name )
	End
	
	Private
	
	Struct Values<T>
	
		Global _valuesMap:=New Map<UniformBuffer,Values>

		Function Get:Values( ubuffer:UniformBuffer )

			Local values:=_valuesMap[ubuffer]
			If values Return values

			values=New Values
			_valuesMap[ubuffer]=values
			Return values
		End
	
		Method Id:Int( name:String )
		
			Local id:=_ids[name]
			If id Return id-1
			
			_values.Push( Null )
			_exists.Push( False )
			
			_ids[name]=_values.Length
			Return _values.Length-1

		End
		
		Method Set( name:String,value:T )
			Local id:=Id( name )
			_values[id]=value
			_exists[id]=True
		End
		
		Method Clear( name:String )
			Local id:=Id( name )
			_exists[ id ]=False
		End
		
		Method Get:T( name:String )
			Local id:=Id( name )
			Return _values[id]
		End
		
		Method Exists:Bool( name:String )
			Local id:=Id( name )
			Return _exists[id]
		End
		
		Private
		
		Field _ids:=New StringMap<Int>
		
		Field _values:=New Stack<T>
		Field _exists:=New Stack<Bool>

	End

End

Function Main()

	Local ubuffer:=New UniformBuffer
	
	ubuffer.Set( "TestInt",1 )
	Print ubuffer.Get<Int>( "TestInt" )

End
