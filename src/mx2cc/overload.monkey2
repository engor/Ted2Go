
Namespace mx2.overload

Private

Function IsCandidate:Bool( func:FuncValue,ret:Type,args:Type[],infered:Type[] )

	Local ftype:=func.ftype
	Local retType:=ftype.retType
	Local argTypes:=ftype.argTypes
	
	If args.Length>argTypes.Length Return False
	
	If ret
		If retType.IsGeneric
			If Not retType.InferType( ret,infered ) Return False
		Else If Not ret.IsGeneric
			If Not retType.ExtendsType( ret ) Return False
		Endif
	Endif

	If ret And retType.IsGeneric And Not retType.InferType( ret,infered ) Return False
	
	For Local i:=0 Until argTypes.Length
	
		If i>=args.Length Or Not args[i]
		
			Local pdecl:=func.pdecls[i]
			
			If Not pdecl.init Return False
			
		Else If argTypes[i].IsGeneric
		
			Local arg:=args[i]
			
			Local flist:=TCast<FuncListType>( arg )
			If flist
			
				Local ftype:=TCast<FuncType>( argTypes[i] )
				If Not ftype Return False
				
				Local func:=flist.FindOverload( Null,ftype.argTypes )
				If Not func Return False
				
				arg=func.ftype
			Endif
			
			If Not argTypes[i].InferType( arg,infered ) Return False
			
		Else
		
			If args[i].DistanceToType( argTypes[i] )<0 Return False

		Endif

	Next
	
	For Local i:=0 Until infered.Length

		If Not infered[i] Or infered[i]=Type.BadType Return False
	Next
	
	Return True
End

Function CanInfer:Bool( func:FuncValue,args:Type[] )

	If Not func.IsGeneric SemantError( "overload.CanInfer()" )

	Local ftype:=func.ftype
	Local argTypes:=ftype.argTypes
	
	Local infered:=New Type[func.types.Length]
	
	For Local i:=0 Until Min( args.Length,argTypes.Length )
		If argTypes[i].IsGeneric And Not argTypes[i].InferType( args[i],infered ) Return False
	Next
	
	For Local i:=0 Until infered.Length
		If Not infered[i] Or infered[i]=Type.BadType Return False
	Next
	
	Return True
End

'return true if func is better than func2
Function IsBetter:Bool( func:FuncValue,func2:FuncValue,args:Type[] )

	Local better:=False,exact:=True

	For Local i:=0 Until args.Length
	
		If Not args[i] Continue
	
		Local dist1:=args[i].DistanceToType( func.ftype.argTypes[i] )
		Local dist2:=args[i].DistanceToType( func2.ftype.argTypes[i] )
		
		If dist1=-1 Or dist2=-1 SemantError( "FuncListType.IsBetter()" )
		
		If dist1>dist2 Return False
		
		If dist1<dist2 better=True
		
		If dist1 exact=False
	Next
	
	If better Return True

	'if exact match, prefer non-generic over generic		
	'
	If exact And Not func.instanceOf And func2.instanceOf Return True
	
	'If exact match, not better.
	'
	If exact Return False
	
	'compare 2 generic func instances!
	'		
	If func.instanceOf And func2.instanceOf
	
		If CanInfer( func2.instanceOf,func.instanceOf.ftype.argTypes ) 
		
			If Not CanInfer( func.instanceOf,func2.instanceOf.ftype.argTypes ) 
			
				Return True

			Endif
			
		Endif
		
	Endif

	Return False
End

Function Linearize( types:Type[],func:FuncValue,funcs:Stack<FuncValue>,j:Int=0 )

	For Local i:=j Until types.Length
	
		Local type:=types[i]
	
		Local flist:=TCast<FuncListType>( type )
		If Not flist Continue
		
		types=types.Slice( 0 )
		
		For Local func2:=Eachin flist.funcs
		
			types[i]=func2.ftype
			
			Linearize( types,func,funcs,i+1 )
		Next
		
		Return
		
	Next
	
	Local func2:=func.TryGenInstance( types )

	If func2 funcs.Push( func2 )
End

Public

Function FindOverload:FuncValue( funcs:Stack<FuncValue>,ret:Type,args:Type[] )

	Local candidates:=New Stack<FuncValue>
	
	For Local func:=Eachin funcs
	
		If Not func.IsGeneric
		
			If IsCandidate( func,ret,args,Null ) candidates.Push( func )
			
			Continue
		Endif
		
		Local infered:=New Type[func.types.Length]
		
		If IsCandidate( func,ret,args,infered ) Linearize( infered,func,candidates )
		
	Next

'	Print "Funcs:"+Join( funcs.ToArray() )
'	Print "Argtypes:"+Join( args )
'	If ret Print "Return:"+ret.ToString()
'	Print "Candidates:"+Join( candidates.ToArray() )
	
	Local best:FuncValue
	
	For Local func:=Eachin candidates
	
		Local better:=True
		
		For Local func2:=Eachin candidates
		
			If func2=func Continue
		
			If IsBetter( func,func2,args ) Continue
			
			better=False
			Exit
		Next
		
		If Not better Continue
		
		If best Return Null
		
		best=func
	Next
	
	Return best
End

