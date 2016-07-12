
Namespace test

Enum MyEnum
	X=1,Y,Z=10
End

Class Map<T>

	Enum Color
		Red,Black
	End

	Field color:Color
		
	Method New()
		color=Color.Red
	End
End


Function Main()

	Local map:=New Map<Int>

	Local x:=MyEnum.X
	Local y:=MyEnum.Y
	
	Local t:=x|y
	
	t|=MyEnum.Z
	
End

