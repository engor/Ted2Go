
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
		my
	End
	
End

dr
Class Test2

	Function Fff(ttt:TestClass, ccc:Canvas)
		ttt.
		cc
	End
	
End
