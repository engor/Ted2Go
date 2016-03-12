
Namespace std

#rem monkeydoc Container interface
#end
Interface IContainer<T>

	Property Empty:Bool()
	
	'Method All:IIterator<T>()

End

Interface ISequence<T> Extends IContainer<T>

	Method Remove( value:T )

	Method Append( value:T )
	
	Method AppendAll( values:T[] )
	
	'Method AppendAll<C>( values:C ) Where C Implements IContainer<T>

End

#rem monkeydoc Iterator interface
#end
Interface IIterator<T> 'Extends IContainer<T>

	Property Valid:Bool()
	
	Property Current:T()
	
	Method Bump()
	
	Method Erase()
	
	Method EraseAll()
	
	Method Insert( value:T )	
	
	Method InsertAll<C>( values:C ) Where C Implements IContainer<T>
	
End
