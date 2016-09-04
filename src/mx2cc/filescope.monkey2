
Namespace mx2

Class FileScope Extends Scope

	Field fdecl:FileDecl
	
	Field nmspace:NamespaceScope
	
	Field usings:Stack<NamespaceScope>
	
	Field toSemant:=New Stack<SNode>

'	Field classexts:=New Stack<ClassType>
	
	Method New( fdecl:FileDecl )
		Super.New( Null )
		
		Local module:=fdecl.module

		Self.fdecl=fdecl
		Self.usings=module.usings
		
		nmspace=Builder.GetNamespace( fdecl.nmspace )
		nmspace.inner.Push( Self )
		outer=nmspace
		
		For Local member:=Eachin fdecl.members

			Local node:=member.ToNode( Self )
			
			If member.IsExtension
			
				nmspace.classexts.Push( TCast<ClassType>( node ) )
				
			Else If member.IsPublic
			
				If Not nmspace.Insert( member.ident,node ) Continue
				
			Else
			
				If Not Insert( member.ident,node ) Continue
				
			Endif

			toSemant.Push( node )
		Next
	End
	
	Method UsingNamespace:Bool( nmspace:NamespaceScope )
		If usings.Contains( nmspace ) Return True
		usings.Push( nmspace )
		Return False
	End
		
	Method UsingInner( nmspace:NamespaceScope )
		For Local scope:=Eachin nmspace.inner
			Local nmspace:=Cast<NamespaceScope>( scope )
			If nmspace UsingNamespace( nmspace )
		Next
	End
	
	Method UsingAll( nmspace:NamespaceScope )
		If UsingNamespace( nmspace ) Return
		For Local scope:=Eachin nmspace.inner
			Local nmspace:=Cast<NamespaceScope>( scope )
			If nmspace UsingAll( nmspace )
		Next
	End
	
	Method Semant()
	
'		Print "Semating:"+fdecl.path

		If nmspace<>Builder.monkeyNamespace
			UsingAll( Builder.monkeyNamespace )
		Endif

		For Local use:=Eachin fdecl.usings
		
			If use="*"
				UsingAll( Builder.rootNamespace )
				Continue
			Endif
		
			If use.EndsWith( ".." )
				Local nmspace:=Builder.GetNamespace( use.Slice( 0,-2 ) )
				UsingAll( nmspace )
				Continue
			Endif
		
			If use.EndsWith( ".*" )
				Local nmspace:=Builder.GetNamespace( use.Slice( 0,-2 ) )
				UsingInner( nmspace )
				Continue
			Endif
			
			Local nmspace:=Builder.GetNamespace( use )
			If nmspace UsingNamespace( nmspace )
		Next
	
		For Local node:=Eachin toSemant
			Try			
				node.Semant()
			Catch ex:SemantEx
			End
		Next
		
	End
	
	Method FindInUsings:SNode( ident:String,istype:Bool )

		Local finder:=New NodeFinder( ident,istype )
		
		For Local nmspace:=Eachin usings
			finder.Find( nmspace )
		Next
		
		Return finder.Found
	End
	
	Method FindNode:SNode( ident:String ) Override
	
		Local node:=Super.FindNode( ident )
		If node Return node
		
		Return FindInUsings( ident,False )
	End
	
	Method FindType:Type( ident:String ) Override
	
		Local type:=Super.FindType( ident )
		If type Return type
		
		Return Cast<Type>( FindInUsings( ident,True ) )
	End
	
	Function FindExtension( finder:NodeFinder,nmspace:NamespaceScope,ctype:ClassType )

		Local exts:=nmspace.FindClassExtensions( ctype )
		If Not exts Return
			
		For Local ext:=Eachin exts
			finder.Find( ext.scope )
		Next
	End
	
	Function FindExtension:SNode( ident:String,istype:Bool,ctype:ClassType )
	
		Local scope:=Scope.Semanting()
		If Not scope Return Null
		
		Local fscope:=scope.FindFile()
		If Not fscope Return Null
		
		Local finder:=New NodeFinder( ident,istype )
		
		'search hierarchy
		Local nmspace:=fscope.nmspace
		While nmspace
			FindExtension( finder,nmspace,ctype )
'			If finder.Found Return finder.Found
			nmspace=Cast<NamespaceScope>( nmspace.outer )
		Wend
		If finder.Found Return finder.Found

		'search usings
		For Local nmspace:=Eachin fscope.usings
			FindExtension( finder,nmspace,ctype )
		Next
		If finder.Found Return finder.Found
		
		Return Null
	End

	Method FindFile:FileScope() Override

		Return Self
	End
	
End
