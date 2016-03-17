
Namespace std

#rem monkeydoc IContainer interface.
#end
Interface IContainer<T>

	'Property Empty:Bool()
	
	'Method All:IIterator<T>()

	'Method Find:IIterator<T>( value:T ) Default...

	
	'For sequences...
	
	'Method Add( value:T )
	
	'Method AddAll( value:T[] ) Default...
	
	'Method AddAll<C>( values:C ) Where C Implements IContainer<T> Default...
	
End

#rem monkeydoc IIterator interface.
#end
Interface IIterator<T>

	'Property Valid:Bool()
	
	'Property Current:T()
	
	'Method Bump()
	
	
	'For sequences...
	
	'Method Erase()
	
	'Method Insert( value:T )
	
End
