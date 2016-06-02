
Namespace std.collections

#rem monkeydoc The IContainer interface is a 'dummy' interface that container classes should implement for compatibility with [[Eachin]] loops.

IContainer does not actually declare any members, but a class that implements IContainer should implement the follow method:

`Method All:IteratorType()` - Gets an iterator to all values in the container.

...where 'IteratorType' is a class or struct type that implements the following properties and methods:

`Property Current:ValueType()` - The current value pointed to by the iterator.

`Property AtEnd:bool()` - true if iterator is at end of container.

`Method Erase()` - Erases the value pointed to by the iterator.

`Method Bump()` - Bumps the iterator so it points to the next value in the container.

...where 'ValueType' is the type of the values contained in the container.

With these conditions met, a container can be used with eachin loops. Monkey2 will automatically convert code like this:

```
For Local value:=Eachin container

	...loop code here...

Next
```

...to this...

```
Local iterator:=container.All()

While Not iterator.AtEnd

	Local value:=iterator.Current
	
	...loop code here...
	
	iterator.Bump()
Wend
```

Containers should not be modified while eachin is being used to loop through the values in the container as this can put the container into
an inconsistent state. If you need to do this, you should manually iterate through the container and use the iterator 'Erase' method to erase
values in a controlled way. For example:

```
Local iterator:=container.All()

While Not iterator.AtEnd

	Local value:=iterator.Current

	Local eraseMe:=false

    ...loop code here - may set eraseMe to true to erase current value...

	If eraseMe

		iterator.Erase()

	Else

		iterator.Bump()
	Endif
Wend
```

Note that if you erase a value, you should NOT bump the iterator - erase implicitly does this for you.

Finally, IContainer is not a 'real' interface because Monkey2 does not yet support generic interface methods. This feature is planned for a 
future version of monkey2.

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

	'Property AtEnd:Bool()
	
	'Property Current:T()
	
	'Method Bump()
	
	
	'For sequences...
	
	'Method Erase()
	
	'Method Insert( value:T )
	
End
