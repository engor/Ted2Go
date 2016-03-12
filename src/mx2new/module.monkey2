
Namespace mx2

Class Module

	Field name:String
	Field srcPath:String
	Field productType:String
	
	Field ident:String
	Field baseDir:String
	Field buildDir:String
	Field cacheDir:String
	Field outputDir:String
	Field hfileDir:String
	Field cfileDir:String

	Field fileDecls:=New Stack<FileDecl>
	Field fileScopes:=New Stack<FileScope>
	
	Field genInstances:=New Stack<SNode>
	Field usings:=New Stack<NamespaceScope>
	Field main:FuncValue
	
	Field moduleDeps:=New Stack<String>
	
	Method New( name:String,srcPath:String,productType:String )
		Self.name=name
		Self.srcPath=srcPath
		Self.productType=productType
		
		Local builder:=Builder.instance
		
		ident=MungPath( name )
		baseDir=ExtractDir( srcPath )
		buildDir=baseDir+name+".buildv002/"
		outputDir=buildDir+builder.profileName+"/"
		cacheDir=buildDir+"build_cache/"+builder.profileName+"/"
		
		cfileDir=cacheDir
		If productType="module" hfileDir=outputDir Else hfileDir=cacheDir
		
		If name<>"monkey" Or productType<>"module" usings.Push( builder.monkeyNamespace )
	End
End

