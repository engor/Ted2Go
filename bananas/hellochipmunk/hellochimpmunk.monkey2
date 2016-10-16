
#Import "<std>"
#Import "<mojo>"
#Import "<chipmunk>"

Using std..
Using mojo..
Using chipmunk..

Class HelloChipmunk Extends Window

	Field space:cpSpace Ptr
	Field ground:cpShape Ptr
	Field ballBody:cpBody ptr
	Field ballShape:cpShape Ptr
	
	Method New()
	
		ClearColor=Color.Black
	
		'Create an empty space.
		space=cpSpaceNew()
		cpSpaceSetGravity( space,cpv( 0,100 ) )

		'Add a static line segment shape for the ground.
		'We'll make it slightly tilted so the ball will roll off.
		'We attach it to space->staticBody to tell Chipmunk it shouldn't be movable.
		ground=cpSegmentShapeNew( cpSpaceGetStaticBody( space ),cpv( -100,15 ), cpv( 100,-15 ),0 )
		cpShapeSetFriction( ground,1 )
		cpSpaceAddShape( space,ground )
		
		'Now let's make a ball that falls onto the line and rolls off.
		'First we need to make a cpBody to hold the physical properties of the object.
		'These include the mass, position, velocity, angle, etc. of the object.
		'Then we attach collision shapes to the cpBody to give it a size and shape.
		
		Local radius:=10
		Local mass:=1
  
		'The moment of inertia is like mass for rotation
		'Use the cpMomentFor*() functions to help you approximate it.
		Local moment:=cpMomentForCircle( mass,0,radius,cpvzero )
		
		'The cpSpaceAdd*() functions return the thing that you are adding.
		'It's convenient to create and add an object in one line.
		ballBody=cpSpaceAddBody( space,cpBodyNew( mass,moment ) )
		cpBodySetPosition( ballBody,cpv( 0,-100 ) )
		
		'Now we create the collision shape for the ball.
		'You can create multiple collision shapes that point to the same body.
		'They will all be attached to the body and move around to follow it.
		ballShape=cpSpaceAddShape( space,cpCircleShapeNew( ballBody,radius,cpvzero ) )
		cpShapeSetFriction( ballShape,0.7 )
	
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		App.RequestRender()
	
		'It is *highly* recommended to use a fixed size time step.
		Local timeStep:=1.0/60.0
		
		cpSpaceStep( space,timeStep )
		
		Local rot:=cpBodyGetRotation( ballBody )
		Local pos:=cpBodyGetPosition( ballBody )
		Local vel:=cpBodyGetVelocity( ballBody )
		
		Print "ball rot="+ATan2( rot.y,rot.x )+", pos.x="+pos.x+", pos.y="+pos.y+", vel.x="+vel.x+", vel.y="+vel.y
		
		canvas.Translate( Width/2,Height/2 )
		
		canvas.DrawCircle( pos.x,pos.y,10 )
		
		canvas.Color=Color.Black
		canvas.DrawLine( pos.x,pos.y,pos.x+rot.x*10,pos.y+rot.y*10 )
		
		canvas.Color=Color.Blue
		canvas.DrawLine( -100,15,100,-15 )
	End
	
	Method Cleanup()	'Yeah, right!
		cpShapeFree( ballShape )
		cpBodyFree( ballBody )
		cpShapeFree( ground )
		cpSpaceFree( space )
	End

End

Function Main()

	New AppInstance
	
	New HelloChipmunk
	
	App.Run()
End
