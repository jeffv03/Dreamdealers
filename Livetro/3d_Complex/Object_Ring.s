ring_obj
	dc.w 1000			zoom
	dc.l ring_ExtraInit		ExtraInit
	dc.l ring_ExtraJump		ExtraJump
	dc.l ring_color			ObjectColor
	dc.l ring_dots
	dc.l ring_elements
	dc.w SCREEN_WIDTH/2		PosX
	dc.w -SCREEN_HEIGHT/2		PosY
	dc.w 0				Alpha
	dc.w 0				Teta
	dc.w 0				Phi
	dc.w 2				BlankLimit

ring_dots
	dc.w 17				nb points
* face du dessus
	dc.w -800,-800,-200
	dc.w -800,800,-200
	dc.w 800,800,-200
	dc.w 800,-800,-200
	dc.w -500,-500,-200
	dc.w -500,500,-200
	dc.w 500,500,-200
	dc.w 500,-500,-200
* face du dessous
	dc.w -800,-800,200
	dc.w -800,800,200
	dc.w 800,800,200
	dc.w 800,-800,200
	dc.w -500,-500,200
	dc.w -500,500,200
	dc.w 500,500,200
	dc.w 500,-500,200
	dc.w 0,0,0

ring_elements
	dc.w 17
	dc.l .face0
	dc.l .face1
	dc.l .face2
	dc.l .face3
	dc.l .face4
	dc.l .face5
	dc.l .face6
	dc.l .face7
	dc.l .face8
	dc.l .face9
	dc.l .face10
	dc.l .face11
	dc.l .face12
	dc.l .face13
	dc.l .face14
	dc.l .face15
	dc.l .sphere1

.face0
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 0,1,1,5,5,4,4,0
.face1
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 1,2,2,6,6,5,5,1
.face2
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 2,3,3,7,7,6,6,2
.face3
	dc.w TYPE_FACE
	dc.w 0
	dc.w 1,-1
	dc.w 4
	dc.w 3,0,0,4,4,7,7,3
.face4
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 8,12,12,13,13,9,9,8
.face5
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 13,14,14,10,10,9,9,13
.face6
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 14,15,15,11,11,10,10,14
.face7
	dc.w TYPE_FACE
	dc.w 0
	dc.w 2,-1
	dc.w 4
	dc.w 8,11,11,15,15,12,12,8

.face8
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 0,8,8,9,9,1,1,0
.face9
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 4
	dc.w 1,9,9,10,10,2,2,1
.face10
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 4
	dc.w 2,10,10,11,11,3,3,2
.face11
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 4
	dc.w 3,11,11,8,8,0,0,3
.face12
	dc.w TYPE_FACE
	dc.w 0
	dc.w 5,-1
	dc.w 4
	dc.w 4,5,5,13,13,12,12,4
.face13
	dc.w TYPE_FACE
	dc.w 0
	dc.w 6,-1
	dc.w 4
	dc.w 5,6,6,14,14,13,13,5
.face14
	dc.w TYPE_FACE
	dc.w 0
	dc.w 3,-1
	dc.w 4
	dc.w 6,7,7,15,15,14,14,6
.face15
	dc.w TYPE_FACE
	dc.w 0
	dc.w 4,-1
	dc.w 4
	dc.w 7,4,4,12,12,15,15,7

.sphere1
	dc.w TYPE_SPHERE
	dc.w 0
	dc.w 7
	dc.w 300
	dc.w 16

ring_color
	incbin Palette2

ring_ExtraInit
	move.w #SCREEN_HEIGHT,Object_Counter-data_base(a5)
	rts

ring_ExtraJump
	moveq #-6,d0
	moveq #4,d1
	moveq #8,d2
	lea ring_obj(pc),a0
	bsr Incrize_Angles

	subq.w #1,Object_Counter-data_base(a5)
	beq Display_Next_Object
	addq.w #2,PosY+ring_obj-data_base(a5)
	rts

