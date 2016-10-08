
Namespace std.resource

#rem

Ok, the basic rules for resource management are:

* If you create a resource using 'New' or 'Load', you must either Retain() it, Discard() it or add it as a dependancy of another resource (same as retaining it really).

* If you Retain() a resource, you must eventually Release() it.

* If you open a resource from a resource manager using an OpenBlah method, it will be managed for you.

* Discarding() a resource manager releases any resources it is managing.

Note:

AddDependancy( r1,r2 ) is pretty much the same as:

r2.Retain()
r1.OnDiscarded+=Lambda()
	r2.Release()
End

Implemented as a stack for now so I can debug it.

#end

Class Resource

	#rem monkeydoc Invoked when the resource is discarded.
	#end
	Field OnDiscarded:Void()
	
	#rem monkeydoc Creates a new resource.
	
	The reference count for a resource is initially 0.
	
	#end
	Method New()

		_live.Push( Self )
	End
	
	#rem monkeydoc True if resource has been discarded.
	#end
	Property Discarded:Bool()
	
		Return _refs=-1
	End

	#rem monkeydoc Retains the resource.
	
	Increments the resource's reference count by 1.
	
	Resources with a reference counter >0 will not be discarded.
	
	#end
	Method Retain()
		DebugAssert( _refs>=0 )
		
		_refs+=1
	End
	
	#rem monkeydoc Releases the resource.
	
	Decrements the resource's reference count by 1.
	
	If the reference count becomes 0, the resource is discarded.
	
	#end
	Method Release()

		DebugAssert( _refs>0 )
		
		_refs-=1
		
		If Not _refs Discard()
	End
	
	#rem monkeydoc Discards the resource.
	
	If the resource's reference count is >0 or the resource has already been discarded, nothing happens.
	
	If the resource's reference count is 0, the resource is discarded. First, OnDiscard() is called, then OnDiscarded() and finally any dependancies are released.
	
	#end
	Method Discard()
		If _refs Return
		
		_refs=-1
		
		_live.Remove( Self )
	
		OnDiscard()
		
		OnDiscarded()
		
		If Not _depends Return
		
		For Local r:=Eachin _depends
			r.Release()
		Next
		
		_depends=Null
	End
	
	#rem monkeydoc Adds a dependancy to the resource.
	
	Adds `resource` to the list of dependancies for this resource and retains it.
	
	When this resource is eventually discarded, `resource` will be automatically released.
	
	#end
	Method AddDependancy( resource:Resource )
		DebugAssert( _refs>=0 And resource._refs>=0 )
		
		If Not _depends _depends=New Stack<Resource>
		
		_depends.Add( resource )
		
		resource.Retain()
	End

	#rem monkeydoc @hidden
	#end	
	Function NumLive:Int()
	
		Return _live.Length
	End
	
	Protected
	
	#rem monkeydoc Called when resource is discarded.
	#end
	Method OnDiscard() Virtual
	End
	
	Private
	
	Global _live:=New Stack<Resource>
	
	Field _refs:Int
	
	Field _depends:Stack<Resource>
End

Class ResourceManager Extends Resource

	Method New()
		If Not _managers
			_managers=New Stack<ResourceManager>
		Endif
		_managers.Push( Self )
	End
	
	Function DebugDeps( r:Resource,indent:String )
	
		If Not r._depends Return
	
		indent+="  "
		For Local d:=Eachin r._depends
			Print indent+String.FromCString( d.typeName() )+", refs="+d._refs
			DebugDeps( d,indent )
		Next
		indent=indent.Slice( 0,-2 )
		
	End
	
	Function DebugAll()
	
		For Local manager:=Eachin _managers
		
			For Local it:=Eachin manager._retained
			
				Print it.Key+", refs="+it.Value._refs
				DebugDeps( it.Value,"" )

			Next
		Next
		
		For Local r:=Eachin _live
			'If Not r._slug Print String.FromCString( r.typeName() )+", ref="+r._refs+", slug="+r._slug
		End
	End
	
	Method OpenResource:Resource( slug:String )
	
		For Local manager:=Eachin _managers
		
			Local r:=manager._retained[slug]
			If Not r Continue
			
			If manager<>Self AddResource( slug,r )
			
			Return r
		Next

		Return Null
	End
	
	Method AddResource( slug:String,r:Resource )
		If Not r Return
		
		DebugAssert( Not r.Discarded,"Can't add discarded resource to resource manager" )

		If _retained.Contains( slug ) Return
		
		_retained[slug]=r
		
		AddDependancy( r )
	End
	
	Protected
	
	Method OnDiscard() Override
	
		_managers.Remove( Self )
	
		_retained=Null
	End
	
	Private
	
	Global _managers:Stack<ResourceManager>
	
	Field _retained:=New StringMap<Resource>

End
