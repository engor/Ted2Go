
Namespace mojox

#rem monkeydoc The TableView class.
#end
Class TableView Extends ScrollView

	#rem monkeydoc Creates a new table view.
	#end
	Method New()
		Style=GetStyle( "TableView" )
		
		_docker=New DockingView
		
		ContentView=_docker
	End
	
	#rem monkeydoc Number of columns.
	#end
	Property NumColumns:Int()
	
		Return _cols.Length
	End
	
	#rem monkeydoc Number of rows.
	#end
	Property NumRows:Int()
	
		Return _numRows
	end

	#rem monkeydoc Adds a column.
	#end	
	Method AddColumn:Int( text:String="",icon:Image=Null,size:String="",draggable:Bool=False )

		Local col:=New TableColumn( text,icon,_rowSizes )
		col.Rows.Resize( _numRows )

		_docker.AddView( col,"left",size,draggable )

		_cols.Push( col )
		
		Return _cols.Length-1
	End
	
	#rem monkeydoc Adds rows.
	#end
	Method AddRows( num:Int )
	
		_numRows+=num
		_rowSizes.Resize( _numRows )
	
		For Local col:=Eachin _cols
			col.Rows.Resize( _numRows )
		Next
	End
	
	#rem monkeydoc Removes all rows.
	#end
	Method RemoveAllRows()
	
		For Local col:=Eachin _cols
			For Local row:=0 Until _numRows
				col.SetView( row,Null )
			Next
			col.Rows.Clear()
		Next
		
		_rowSizes.Clear()
		
		_numRows=0
	End
	
	#rem monkeydoc Removes all rows and columns.
	#end
	Method RemoveAll()
	
		RemoveAllRows()
	
		_docker.RemoveAllViews()
		
		_cols.Clear()
	End
	
	#rem monkeydoc Gets the view at a cell location.
	#end
	Operator[]:View( col:Int,row:Int )
		Assert( col>=0 And col<_cols.Length And row>=0 And row<_numRows )
	
		Return _cols[col].Rows[row]
	End
	
	#rem monkeydoc Sets the view at a cell location.
	#end
	Operator[]=( col:Int,row:Int,view:View )
		Assert( col>=0 And col<_cols.Length And row>=0 And row<_numRows )
		
		_cols[col].SetView( row,view )
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=Super.OnMeasure()
		
		Local h:=0
		For Local i:=0 Until _rowSizes.Length
			h+=_rowSizes[i]
		Next
		
		size.y=Max( h,size.y )
		
		Return size
	End
	
	Method OnLayout() Override
	
		Super.OnLayout()
		
		For Local i:=0 Until _rowSizes.Length
'			_rowSizes[i]=0
		Next
	End
	
	Private
	
	Class TableColumn Extends View
	
		Method New( text:String,icon:Image,rowSizes:Stack<Int> )
			
			Style=GetStyle( "TableColumn" )
			
			_rowSizes=rowSizes
			
			_header=New Label( text,icon )
			
			_header.Style=GetStyle( "TableHeader" )
			
			AddChildView( _header )
		End
		
		Property Rows:Stack<View>()
		
			Return _rows
		End
		
		Method SetView( row:Int,view:View )
		
			If _rows[row] RemoveChildView( _rows[row] )
			
			_rows[row]=view
			
			If _rows[row] AddChildView( _rows[row] )
		End
		
		Protected
		
		Method OnMeasure:Vec2i() Override
		
			Local size:=_header.LayoutSize
			
			For Local i:=0 Until _rows.Length
			
				Local view:=_rows[i]
				If Not view Continue
				
				_rowSizes[i]=Max( _rowSizes[i],view.LayoutSize.y )
				
				size.x=Max( size.x,view.LayoutSize.x )
				
				size.y+=view.LayoutSize.y
			Next
			
			Return size
		End

		Method OnLayout() Override
		
			_header.Frame=New Recti( 0,0,Width,_header.LayoutSize.y )
			
			Local y:=_header.LayoutSize.y
			
			For Local i:=0 Until _rows.Length
				
				Local view:=_rows[i]
				
				Local y2:=y+_rowSizes[i]
				If view view.Frame=New Recti( 0,y,Width,y2 )
				y=y2
				
			Next
		End
		
		Private
		
		Field _header:Label
		
		Field _rowSizes:Stack<Int>
		
		Field _rows:=New Stack<View>
	End
	
	Field _docker:DockingView
	
	Field _numRows:Int
	
	Field _rowSizes:=New Stack<Int>
	
	Field _cols:=New Stack<TableColumn>
	
End
