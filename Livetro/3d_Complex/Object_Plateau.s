plateau_obj
	dc.w 1500				zoom
	dc.l plateau_ExtraInit			ExtraInit
	dc.l plateau_ExtraJump			ExtraJmp
	dc.l plateau_Color			ObjectColor
	dc.l plateau_dots
	dc.l plateau_elements
	dc.w -SCREEN_WIDTH/2			Pos X
	dc.w SCREEN_HEIGHT/2			Pos Y
	dc.w 0					alpha
	dc.w 0					teta
	dc.w 0					phi
	dc.w 3					BlankLimit
	
plateau_dots
	dc.w 32					nb de point
	dc.w 500,500,0
	dc.w 500,-500,0
	dc.w -500,-500,0
	dc.w -500,500,0
	dc.w 500,500,-500
	dc.w 500,-500,-500
	dc.w -500,-500,-500
	dc.w -500,500,-500
	dc.w 500,500,500
	dc.w 500,-500,500
	dc.w -500,-500,500
	dc.w -500,500,500
	dc.w 500,500,-1000
	dc.w 500,-500,-1000
	dc.w -500,-500,-1000
	dc.w -500,500,-1000
	dc.w 500,500,1000
	dc.w 500,-500,1000
	dc.w -500,-500,1000
	dc.w -500,500,1000
	dc.w 500,500,-1500
	dc.w 500,-500,-1500
	dc.w -500,-500,-1500
	dc.w -500,500,-1500
	dc.w 500,500,1500
	dc.w 500,-500,1500
	dc.w -500,-500,1500
	dc.w -500,500,1500
	dc.w 800,800,0
	dc.w 800,-800,0
	dc.w -800,-800,0
	dc.w -800,800,0

plateau_elements
	dc.w 11					nb de structure �l�ment
	dc.l .face1
	dc.l .face2
	dc.l .face3
	dc.l .face4
	dc.l .face5
	dc.l .face6
	dc.l .face7
	dc.l .line1
	dc.l .line2
	dc.l .line3
	dc.l .line4

.face1
	dc.w TYPE_FACE				type de l'�l�ment
	dc.w 0					profondeur de l'�l�ment
	dc.w 1,1				couleur
	dc.w 4					4 lignes
	dc.w 0,1,1,2,2,3,3,0
.face2
	dc.w TYPE_FACE				type de l'�l�ment
	dc.w 0					profondeur de l'�l�ment
	dc.w 2,3				couleur
	dc.w 4					4 lignes
	dc.w 4,5,5,6,6,7,7,4
.face3
	dc.w TYPE_FACE				type de l'�l�ment
	dc.w 0					profondeur de l'�l�ment
	dc.w 3,2				couleur
	dc.w 4					4 lignes
	dc.w 8,9,9,10,10,11,11,8
.face4
	dc.w TYPE_FACE				type de l'�l�ment
	dc.w 0					profondeur de l'�l�ment
	dc.w 4,5				couleur
	dc.w 4					4 lignes
	dc.w 12,13,13,14,14,15,15,12
.face5
	dc.w TYPE_FACE				type de l'�l�ment
	dc.w 0					profondeur de l'�l�ment
	dc.w 5,4				couleur
	dc.w 4					4 lignes
	dc.w 16,17,17,18,18,19,19,16
.face6
	dc.w TYPE_FACE				type de l'�l�ment
	dc.w 0					profondeur de l'�l�ment
	dc.w 6,7				couleur
	dc.w 4					4 lignes
	dc.w 20,21,21,22,22,23,23,20
.face7
	dc.w TYPE_FACE				type de l'�l�ment
	dc.w 0					profondeur de l'�l�ment
	dc.w 7,6				couleur
	dc.w 4					4 lignes
	dc.w 24,25,25,26,26,27,27,24
.line1
	dc.w TYPE_LINE
	dc.w 0
	dc.w 1
	dc.w 28,29
.line2
	dc.w TYPE_LINE
	dc.w 0
	dc.w 1
	dc.w 29,30
.line3
	dc.w TYPE_LINE
	dc.w 0
	dc.w 1
	dc.w 30,31
.line4
	dc.w TYPE_LINE
	dc.w 0
	dc.w 1
	dc.w 31,28

plateau_Color
	incbin Palette1

plateau_ExtraInit
	move.w #SCREEN_WIDTH,Object_Counter-data_base(a5)
	rts

plateau_ExtraJump
	moveq #-2,d0
	moveq #4,d1
	moveq #6,d2
	lea plateau_obj(pc),a0
	bsr Incrize_Angles

	subq.w #1,Object_Counter-data_base(a5)
	beq Display_Next_Object
	addq.w #2,PosX+plateau_obj-data_base(a5)
	rts

