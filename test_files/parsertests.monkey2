
Function FnLambda(p1:String, p2:Void(x:Int,y:Int), p3:Float)

End

Function LambdaFn(p1:String, p2:Void(x:Int,y:Int), p3:Float)

End

#Rem
Class Aa Extends Stream Implements IIntegral,IIterator

End
#End

Class AAA Extends TestClass
	
End


Class TestClass
	
	Function MyFyncPub:String()
		Return "func"
	End
	
	Method MyMethodPub:Float()
		Return 1.6
	End
	
	Property Prop:Test2()
		Return New Test2
	End
	
	Field PubField:String
	
	Protected
	
	Function MyFyncProt:String()
		Return "func-prot"
	End
	
	Field ProtField:String
	
	Private
	
	Field _tst := .14
	
	Method MyMethodPriv(mymy:Int)
		
		FnLambda("", Lambda(xxx:Int,yyy:Int)
		
		End, 2.8)
		
		LambdaFn("", Lambda( aaa:Int,bbb:Int)
			
			Local d := 1.15
			
		End, 2.8)
		
	End
	
	Method DVD()
	
	End
	
End


Class Test2

	Function Fff(ttt:TestClass, ccc:Canvas)
	End
	
End
