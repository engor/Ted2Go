'Operator Overloading Example 2
'Reference(s):
'http://monkey2.monkey-x.com/forums/topic/operator-overloading/
'https://en.wikipedia.org/wiki/Operator_overloading

#Import "<std.monkey2>"

Using std

Function Main()

	Local objA:=New MyClass("Gold", 100)
	Local objB:=New MyClass("Silver", 90)
	
	Print ""
	
	If (objA > objB) Then Print objA.Label + " > " + objB.Label
	If (objA < objB) Then Print objA.Label + " < " + objB.Label

	If (objA = objB) Then Print objA.Label + " = " + objB.Label
	If (objA <> objB) Then Print objA.Label + " <> " + objB.Label
	
	Print ""
	
End


Class MyClass
	
	Private
	
		Field _label:String
		Field _value:UByte
	
	Public
		
		Method New(label:String, value:UByte)
			Label = label
			_value = value
		End
		
		Property Label:String()
			Return _label
		Setter(label:String)
			_label = label
		End

		'This will give you >, <, >=, <=, = and <> for free!		
		Operator<=>:Int( o2:MyClass )
			Return Self._value<=>o2._value
		End

End
