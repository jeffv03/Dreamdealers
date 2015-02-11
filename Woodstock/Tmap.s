 


*			Labyrinthe en 3D avec des textures mapp�es
*			~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*				(c)1994-1995 Sync/DreamDealers





*********************************************************************************
*                                Les includes                                   *
*********************************************************************************
	incdir "Textures/"



LOAD_TEXTURE_BMP MACRO
	dc.w \1
\2_BMP=*
	incbin "\2.BMP"
\2_PAL=*
	incbin "\2.PAL"
	ENDM

LOAD_TEXTURE_CHK MACRO
	incbin "\1.PAL"
	incbin "\1.CHK"
	ENDM


*********************************************************************************
*                                   Les EQUs                                    *
*********************************************************************************
DATA_OFFSET=$7ffe

NB_COLONNES=96
NB_LIGNES=60
NB_ZOOM=NB_LIGNES+200
COP_SKIP=255*4
COP_SIZE_X=(3+NB_COLONNES+1+1)*4
COP_SIZE=COP_SKIP+COP_SIZE_X*NB_LIGNES+4

PIXEL_SIZE_X=2
PIXEL_SIZE_Y=3
SCREEN_X=192
SCREEN_Y=NB_LIGNES*PIXEL_SIZE_Y
SCREEN_DEPTH=7
SCREEN_WIDTH=(SCREEN_X+7)/8

TEXTURE_X=80
TEXTURE_Y=64
NB_TEXTURES=3
TEXTURE_SHADE=7
TEXTURE_BITPLAN_LINE_SIZE=(TEXTURE_X+7)/8
TEXTURE_BITPLAN_SIZE=TEXTURE_BITPLAN_LINE_SIZE*TEXTURE_Y
TEXTURE_SIZE=TEXTURE_X*TEXTURE_Y*2

LABY_X=40
LABY_Y=39

WALL_SHIFT=5
WALL_SIZE=1<<WALL_SHIFT
BAK_SIZE=9
BEGIN_WALL=WALL_SIZE*(BAK_SIZE-1)/2+WALL_SIZE/2

SRC_REG=0
DEST_REG=1
TEMP_REG=0

SHIFT=7
ZOOM=24
MOVE_AREA=7
MAX_ANGLE=360
MAX_MOVE_SPEED=$7fff
MAX_ROTATE_SPEED=12

PLAYER=1


	rsreset
Rotate_struct	rs.b 0
CaseOffset	rs.w 1
Coord_X1	rs.w 1
Coord_Y1	rs.w 1
Coord_X2	rs.w 1
Coord_Y2	rs.w 1
Rotate_SIZEOF	rs.b 0

	rsreset
Laby_Struct	rs.b 0
Laby_PosX	rs.w 1
Laby_PosY	rs.w 1
Laby_Angle	rs.w 1
Laby_Data	rs.b 0




	section toto,code


* Routine d'initialisation pour le labyrinthe mapp�
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Tmap_Init
	movem.l a5/a6,-(sp)

	lea _Tmap_DataBase,a5			on precalcule tout �a !

* initialisations
* ~~~~~~~~~~~~~~~
	move.w #30*50,Tmap_Compteur(a5)
	sf Tmap_End(a5)

	bsr Build_Screen
	bsr Build_Coplists
	bsr Build_Org_Coplist
	bsr Build_Table_Screen_Offset
	bsr Build_Textures
	bsr Build_Laby_Texture
	bsr Build_Table_Zoom
	bsr Build_Table_Rotate
	bsr Init_Observateur
	bsr Init_Sprites

	movem.l (sp)+,a5/a6
	rts


* La boucle principale
* ~~~~~~~~~~~~~~~~~~~~
Tmap_Initial_PC
	movem.l a5/a6,-(sp)

	lea _Tmap_DataBase,a5
	lea _CustomBase,a6

	bsr.s Clear_Coplists

	move.w #$83e0,dmacon(a6)		set | pri | master | bpl | copper | blitter | sprites
	move.l #Tmap_VBL,$6c.w
Tmap_Main_Loop
	bsr Flip_Coplists
	bsr Clear_log_coplist
	bsr Display_Walls

	tst.w Tmap_End(a5)
	beq.s Tmap_Main_Loop

	WAIT_VHSPOS
	move.w #$0060,dmacon(a6)		vire dma blitter + sprites

	movem.l (sp)+,a5/a6
	rts



Tmap_VBL
	SAVE_REGS

	jsr P61_Music

	jsr Check_Quick_Exit

	lea _Tmap_DataBase,a5
	lea _CustomBase,a6

	bsr Gestion_Joystick
	bsr Check_Collisions

	subq.w #1,Tmap_Compteur(a5)
	bne.s .skip
	st Tmap_End(a5)
.skip
	st Flip_Flag(a5)
	move.w #$0020,intreq(a6)
	RESTORE_REGS
	rte



*************************
* Effacage des coplists *
*************************
Clear_Coplists
	lea Coplist_space,a0
	add.l #COP_SKIP+4+2,a0

	moveq #NB_LIGNES-1,d2
.clear_Y
	moveq #3-1,d0
.clear_X
	moveq #32-1,d1
.clear_bloc
	clr.w (a0)
	clr.w COP_SIZE(a0)
	clr.w (COP_SIZE*2.l,a0)
	addq.l #4,a0
	dbf d1,.clear_bloc
	addq.l #4,a0
	dbf d0,.clear_X
	addq.l #8,a0
	dbf d2,.clear_Y
	rts



*********************************************************************************
*                           Permutation des coplists                            *
*   -->	a5=_Tmap_DataBase                                                            *
*	a6=_Custom                                                              *
*********************************************************************************
Flip_Coplists
	sf Flip_Flag(a5)

	movem.l Log_Coplist(a5),d0-d5
	exg d0,d1				�change des coplists
	exg d1,d2

	exg d3,d4
	exg d4,d5				�change des Table_Screen_Offset
	movem.l d0-d5,Log_Coplist(a5)

	move.l d2,cop1lc(a6)			init la nouvelle coplist
.wait	tst.b Flip_Flag(a5)
	beq.s .wait
	clr.w copjmp1(a6)
	rts



*********************************************************************************
*                        Effacage de la coplist logique                         *
*   -->	a5=_Tmap_DataBase                                                            *
*	a6=_Custom                                                              *
*********************************************************************************
Clear_log_coplist
	move.l Tmp_Coplist(a5),a0
	lea COP_SKIP+2(a0),a0

	WAIT_BLITTER
	move.l #org_coplist,bltapt(a6)
	move.l a0,bltdpt(a6)
	move.l #$09f00000,bltcon0(a6)
	move.l #$00000002,bltamod(a6)		bltamod=0 ; bltdmod=2
	moveq #-1,d0
	move.l d0,bltafwm(a6)
	move.l #((COP_SIZE_X/4)*NB_LIGNES<<16)|(1),bltsizV(a6)
	rts



*********************************************************************************
*				Gestion du joystick				*
*   -->	a5=_Tmap_DataBase								*
*********************************************************************************
Check_Collisions
	move.w Angle(a5),d0			projette la vitesse sur les
	move.w Speed(a5),d1			axe
	move.w d1,d2
	lea Table_Sinus(pc),a0

	muls.w (a0,d0.w*2),d1			Sin(Angle)
	add.l d1,d1
	swap d1
	ext.l d1				vitesse sur les X
	add.l d1,d1
	add.l d1,d1
	add.l d1,d1

	muls.w (90*2,a0,d0.w*2),d2		Cos(Angle)
	add.l d2,d2
	swap d2
	ext.l d2				vitesse sur les Y
	add.l d2,d2
	add.l d2,d2
	add.l d2,d2

	add.l d1,PosX(a5)
	sub.l d2,PosY(a5)


	movem.l PosX-2(a5),d0/d1		on recherche o� on est dans le labyrinthe
	move.w d0,d2
	move.w d1,d3
	lsr.w #WALL_SHIFT,d2
	lsr.w #WALL_SHIFT,d3
	mulu.w #LABY_X,d3
	add.w d3,d2
	lea Packed_Laby+Laby_Data(pc),a0
	lea (a0,d2.w*2),a0			on doit etre ici!

	and.w #WALL_SIZE-1,d0
	and.w #WALL_SIZE-1,d1
	moveq #0,d2				limite Nord
	moveq #WALL_SIZE-1,d3			limite Est
	moveq #WALL_SIZE-1,d4			limite Sud
	moveq #0,d5				limite Ouest

	tst.w -LABY_X*2(a0)
	beq.s .no_Nord
	moveq #(WALL_SIZE-MOVE_AREA)/2,d2
.no_Nord
	tst.w 2(a0)
	beq.s .no_Est
	moveq #(WALL_SIZE+MOVE_AREA)/2,d3
.no_Est
	tst.w LABY_X*2(a0)
	beq.s .no_Sud
	moveq #(WALL_SIZE+MOVE_AREA)/2,d4
.no_Sud
	tst.w -2(a0)
	beq.s .no_Ouest
	moveq #(WALL_SIZE-MOVE_AREA)/2,d5
.no_Ouest


.Clip_Test
	cmp.w d2,d1
	bge.s .ok_Nord
	move.w d2,d1
.ok_Nord
	cmp.w d3,d0
	ble.s .ok_Est
	move.w d3,d0
.ok_Est
	cmp.w d4,d1
	ble.s .ok_Sud
	move.w d4,d1
.ok_Sud
	cmp.w d5,d0
	bge.s .ok_Ouest
	move.w d5,d0
.ok_Ouest
	movem.l PosX-2(a5),d2/d3
	and.w #WALL_SIZE-1,d2
	and.w #WALL_SIZE-1,d3
	sub.w d0,d2
	sub.w d2,PosX(a5)
	sub.w d1,d3
	sub.w d3,PosY(a5)
	rts



Gestion_Joystick
	bsr.s Check_JoyMove
	bra check_angle

Check_JoyMove
	IFNE PLAYER
	btst #7,ciaapra				on change de controle ?
	bne.s .no_fire

	sf Player_On(a5)
	ENDC

.no_fire
	tst.b Player_On(a5)			on utilise le joystick ?
	beq.s .human_player


* Bon.. On simule le joystick
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~
.computer_player
	subq.b #1,Player_Timer(a5)
	bne.s .not_end_timer
	
* on charge ici une nouvelle directive joystick
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.end_timer
	move.l Table_Player(a5),a0
	move.b (a0)+,Player_Timer(a5)		met en place le timer
	bne.s .no_restore

* red�marre au d�but de la table
	bsr Init_Observateur			HUM...
	bra.s .end_timer
.no_restore

* lit la valeur du joystick
	move.b (a0)+,Player_Joy+1(a5)		octet dans un mot

* sauve le ptr
	move.l a0,Table_Player(a5)

* Envoie une valeur pour simuler le joystick
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.not_end_timer
	move.w Player_Joy(a5),d0
	bra.s .end_player



* On a un humain en face => utilisation du joystick
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.human_player
	move.w joy1dat(a6),d0

	ror.b #2,d0
	lsr.w #4,d0
	and.w #%111100,d0
.end_player
	jmp JoyRout(pc,d0.w)
JoyRout
	bra.w move_none			%0000
	bra.w move_down			%0001
	bra.w move_down_left		%0010
	bra.w move_right		%0011
	bra.w move_up			%0100
	bra.w move_none
	bra.w move_none
	bra.w move_up_right		%0111
	bra.w move_up_left		%1000
	bra.w move_none
	bra.w move_none
	bra.w move_none
	bra.w move_left			%1100
	bra.w move_down_right		%1101
	bra.w move_none
	bra.w move_none

move_none
	bsr.s decrize_angle
	bra.s decrize_speed

decrize_angle
	moveq #1,d0
	tst.w Angle_Speed(a5)
	beq.s .no_decrize_angle
	bpl.s .do
	neg.w d0
.do
	sub.w d0,Angle_Speed(a5)
.no_decrize_angle
	move.w Angle_Speed(a5),d0
	asr.w #2,d0
	add.w d0,Angle(a5)
move_exit
	rts

decrize_speed
	move.w #1200,d0
	tst.w Speed(a5)
	beq.s .no_decrize_speed
	bpl.s .do_pl
.do_mi
	add.w #1200,Speed(a5)
	ble.s .no_decrize_speed
	clr.w Speed(a5)
	rts
.do_pl
	sub.w #1200,Speed(a5)
	bge.s .no_decrize_speed
	clr.w Speed(a5)
.no_decrize_speed
	rts

check_angle
	tst.w Angle(a5)				fait gaffe � l'angle de vision
	bge.s .ok1
	add.w #MAX_ANGLE,Angle(a5)
	bra.s .ok2
.ok1	cmp.w #MAX_ANGLE,Angle(a5)
	blt.s .ok2
	sub.w #MAX_ANGLE,Angle(a5)
.ok2
	rts

move_up
	bsr.s decrize_angle
move_up2
	add.w #8000,Speed(a5)
	cmp.w #MAX_MOVE_SPEED,Speed(a5)
	bls.s move_exit
	move.w #MAX_MOVE_SPEED,Speed(a5)
	rts

move_down
	bsr.s decrize_angle
move_down2
	sub.w #8000,Speed(a5)
	cmp.w #-MAX_MOVE_SPEED,Speed(a5)
	bhi.s move_exit
	move.w #-MAX_MOVE_SPEED,Speed(a5)
	rts

move_left
	bsr.s decrize_speed
move_left2
	subq.w #2,Angle_Speed(a5)
	cmp.w #-MAX_ROTATE_SPEED,Angle_Speed(a5)
	bge.s .set_angle
	move.w #-MAX_ROTATE_SPEED,Angle_Speed(a5)
.set_angle
	move.w Angle_Speed(a5),d0
	asr.w #2,d0
	add.w d0,Angle(a5)
	rts

move_right
	bsr decrize_speed
move_right2
	addq.w #2,Angle_Speed(a5)
	cmp.w #MAX_ROTATE_SPEED,Angle_Speed(a5)
	ble.s .set_angle
	move.w #MAX_ROTATE_SPEED,Angle_Speed(a5)
.set_angle
	move.w Angle_Speed(a5),d0
	asr.w #2,d0
	add.w d0,Angle(a5)
	rts

move_up_left
	bsr.s move_up2
	bra.s move_left2

move_up_right
	bsr.s move_up2
	bra.s move_right2

move_down_left
	bsr.s move_down2
	bra.s move_left2

move_down_right
	bsr.s move_down2
	bra.s move_right2



*********************************************************************************
*                              Affichage des murs                               *
*   -->	a5=_Tmap_DataBase                                                            *
*	a6=_Custom                                                              *
*********************************************************************************
Display_Walls
	movem.l a5/a6,-(sp)

	movem.l PosX-2(a5),d2/d4		d�calage par rapport au milieu d'une dalle
	and.w #WALL_SIZE-1,d2			garde que les bits sur une dalle
	and.w #WALL_SIZE-1,d4
	sub.w #WALL_SIZE/2,d2			recentrage sur la dalle
	sub.w #WALL_SIZE/2,d4

	lea Table_Sinus(pc),a0
	move.w Angle(a5),d3
	move.w (90*2,a0,d3.w*2),d0		Cos(Angle)
	move.w (a0,d3.w*2),d1			Sin(Angle)

	neg.w d4
	move.w d2,d3				sauve X et Y...
	move.w d4,d5

	muls.w d0,d2				X*Cos(TETA)
	muls.w d1,d4				Y*Sin(TETA)
	sub.l d4,d2				NX=X*Cos(TETA)-Y*Sin(TETA)
	add.l d2,d2
	swap d2
	ext.l d2

	muls.w d1,d3				X*Sin(TETA)
	muls.w d0,d5				Y*Cos(TETA)
	add.l d5,d3				NY=X*Sin(TETA)+Y*Cos(TETA)
	add.l d3,d3
	swap d3
	IFNE ZOOM
	sub.w #ZOOM,d3
	ENDC

* d2=NX et d3=NY+ZOOM  :  offset � rajouter aux murs

	move.w Angle(a5),d0			recherche la table de rotation
	move.l (Table_Rotate_Offset.l,a5,d0.w*4),a2

	clr.l -(sp)
	move.w (a2)+,2(sp)			Nb de murs dans la table

	move.l Log_Table_Screen_Offset(a5),a3
	lea Table_Zoom_Offset(a5),a4

	movem.l PosX-2(a5),d4/d5		on recherche o� on est dans le labyrinthe
	lsr.w #WALL_SHIFT,d4
	lsr.w #WALL_SHIFT,d5
	subq.w #(BAK_SIZE-1)/2,d4
	subq.w #(BAK_SIZE-1)/2,d5
	mulu.w #LABY_X,d5
	add.w d5,d4
	lsl.w #4,d4				mulu.w #4*4,d4   4 murs par case / table de LONG
	move.l Laby_Texture(a5),a5
	lea (a5,d4.w),a5			on doit etre ici!

loop_display_walls
	move.w (a2)+,d4				lit l'offset de la case
	move.l (a5,d4.w),d4			euh.. ya un mur au fait ici ?
	beq no_wall
	move.l d4,a6				houba! c'est le pointeur sur la texture !

	movem.w (a2)+,d4/d6
	sub.l d2,d4
	asl.l #SHIFT,d4
	move.l #24<<SHIFT,d5
	sub.w d3,d6
	blt wall_not_visible_divs
	beq.s .no_divs1
	divs.w d6,d4				d4=X1
	divs.w d6,d5				d5=Y1
.no_divs1

	movem.w (a2)+,d6/d7
	sub.l d2,d6
	asl.l #SHIFT,d6
	move.l #24<<SHIFT,d0
	sub.w d3,d7
	blt wall_not_visible
	beq.s .no_divs2
	divs.w d7,d6				d6=X2
	divs.w d7,d0				d0=Y2
.no_divs2

	sub.w d4,d6				d6=DeltaX
	ble.s wall_not_visible
	sub.w d5,d0				d0=DeltaY

	add.w #1+NB_COLONNES/2,d4		recentrage sur l'�cran

	ext.l d6

	move.l #TEXTURE_X<<16,d7
	divu.l d6,d7				d7=IncX sur la texture

	swap d0
	clr.w d0
	divs.l d6,d0
	exg d0,d6				d6=IncY sur l'�cran   d0=DeltaX

	swap d5					c'est le Y de d�part
	clr.w d5

	moveq #0,d1				position X dans la texture

	tst.w d4				X1>=0 ?
	bge.s .test_X1_lt
	add.w d4,d0				X1+DeltaX>=0 ?
	ble.s wall_finish			si n�gatif on se casse !
	sub.w d4,d0
.loop_X1_ge
	add.l d6,d5				passe � un autre Y
	add.l d7,d1				colonne suivante dans la texture
	subq.w #1,d0
	addq.w #1,d4				colonne suivante sur l'�cran
	blt.s .loop_X1_ge
	bra.s .test_X1_lt
.loop_X1_lt
	swap d1
	lea (a6,d1.w*2),a0			c'est la colonne � zoomer de la texture
	swap d1
	move.l (a3,d4.w*4),a1			on �crit dans cette colonne de la coplist
	tst.w (a1)				d�ja remplie cette colonne ?
	bne.s .already_done

	swap d5
	cmp.w #NB_ZOOM,d5			ouia.. zoom limit� en hauteur ! FUCK PRECALC !!
	bge.s .no_zoom
	move.l d0,-(sp)
	jsr (a4,d5.w*8)				zoom moi ca gamin !
	move.l (sp)+,d0
.no_zoom
	swap d5
.already_done

	add.l d6,d5
	add.l d7,d1
	addq.w #1,d4
.test_X1_lt
	cmp.w #NB_COLONNES,d4
	dbge d0,.loop_X1_lt
	
wall_finish
	subq.l #1,(sp)
	bne loop_display_walls
	addq.l #4,sp				bouffe le compteur
	movem.l (sp)+,a5/a6
	rts

no_wall
	addq.l #Rotate_SIZEOF-Coord_X1,a2	ya po mur...
wall_not_visible
	subq.l #1,(sp)
	bne loop_display_walls
	addq.l #4,sp				bouffe le compteur
	movem.l (sp)+,a5/a6
	rts

wall_not_visible_divs
	addq.l #4,a2
	bra.s wall_not_visible













*********************************************************************************
*                      Fabrication de l'�cran pour le zoom                      *
*   -->	a5=_Tmap_DataBase                                                            *
*********************************************************************************
Build_Screen
	move.l #Screen_space,a0
	move.l a0,Screen(a5)

* efface d�ja le buffer
* ~~~~~~~~~~~~~~~~~~~~~
	move.l a0,a1
	moveq #(SCREEN_WIDTH/4)-1,d0
.clear
	clr.l (a1)+
	dbf d0,.clear

* construction de 2 lignes du motif
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Build_Motif
	moveq #32,d0

* Fabrication d'une ligne du motif
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   -->	d0=Couleur de d�part
*	a0=Ecran
* <--	a0=Ecran
Build_Motif_Lines
	moveq #0,d1				PosX
Build_Motif_One_Line
	move.w d1,d2
	lsr.w #3,d2				pointe des octets
	move.w d1,d3
	not.w d3				# du bit � modifier

	moveq #SCREEN_DEPTH-1,d4		on se fait tous les bitplans
	move.w d0,d5
put_pixel
	lsr.w #1,d5				sort un bit de la couleur
	bcc.s .clear				c'est quoi ?
.set	bset d3,(a0,d2.w)			met le bit
.branch
	add.w #SCREEN_WIDTH,d2			ligne suivante
	dbf d4,put_pixel

	moveq #0,d2				incr�mente la position
	move.w d1,d2				du point
	addq.w #1,d1
	divu.w #PIXEL_SIZE_X,d2
	swap d2
	tst.w d2
	bne.s .skip

	addq.w #1,d0				couleur suivante

.skip	cmp.w #SCREEN_X,d1
	bne.s Build_Motif_One_Line
	rts
.clear	bclr d3,(a0,d2.w)			efface le bit
	bra.s .branch



*********************************************************************************
*                       Contruction des coplists de la demo                     *
*   -->	a5=_Tmap_DataBase                                                            *
*********************************************************************************
Build_Coplists
	lea Coplist_space,a0
	move.l a0,Log_Coplist(a5)
	bsr.s Build_One_Coplist
	move.l a0,Tmp_Coplist(a5)
	bsr.s Build_One_Coplist
	move.l a0,Phy_Coplist(a5)
Build_One_Coplist
	move.l #(fmode<<16)|(%1111),(a0)+
	move.l #(bplcon0<<16)|($7201),(a0)+	pas de ECSENA
	move.l #(bplcon1<<16)|($ccff),(a0)+
	move.l #(bplcon2<<16)|($3f),(a0)+
	move.l #(bplcon4<<16)|($0000),(a0)+
	move.l #(ddfstrt<<16)|($38),(a0)+
	move.l #(ddfstop<<16)|($78),(a0)+
	move.l #(diwstrt<<16)|($4d80),(a0)+
;;	move.l #(diwstop<<16)|((($4d+SCREEN_Y)&$ff)<<8)|(($80+SCREEN_X)&$ff),(a0)+
	move.l #(diwstop<<16)|((($4d+SCREEN_Y)&$ff)<<8)|$80,(a0)+
	move.l #(bpl1mod<<16)|((-SCREEN_WIDTH)&$ffff),(a0)+
	move.l #(bpl2mod<<16)|((-SCREEN_WIDTH)&$ffff),(a0)+

* Mise en place des sprites
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #8-1,d0
	move.w #spr0ptH,d1
Build_SprPtr
	move.w d1,(a0)+				sprXptH
	addq.l #2,a0
	addq.w #2,d1
	move.w d1,(a0)+				sprXptL
	addq.l #2,a0
	addq.w #2,d1
	dbf d0,Build_SprPtr

* Mise en place des pointeurs videos
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #SCREEN_DEPTH-1,d0
	move.w #bpl1ptH,d1
	move.l Screen(a5),d2
Build_BplPtr
	move.w d1,(a0)+				bplxptH
	swap d2
	move.w d2,(a0)+
	addq.w #2,d1
	move.w d1,(a0)+				bplxptL
	swap d2
	move.w d2,(a0)+
	addq.w #2,d1
	add.l #SCREEN_WIDTH,d2
	dbf d0,Build_BplPtr

* Met en place les couleurs
* ~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #(bplcon3<<16)|($0002),(a0)+
	move.l #(color00<<16)|$305,(a0)+
	move.l #(color01<<16)|$fff,(a0)+
	move.l #(color05<<16)|$fff,(a0)+
	move.l #(color09<<16)|$fff,(a0)+
	move.l #(color13<<16)|$fff,(a0)+
	move.l #(bplcon3<<16)|($8002),(a0)+
	move.l #(color00<<16)|$305,(a0)+

	move.l #(bplcon3<<16)|($0202),(a0)+
	move.l #(color00<<16)|$000,(a0)+
	move.l #(color01<<16)|$fff,(a0)+
	move.l #(color05<<16)|$fff,(a0)+
	move.l #(color09<<16)|$fff,(a0)+
	move.l #(color13<<16)|$fff,(a0)+
	move.l #(bplcon3<<16)|($8202),(a0)+
	move.l #(color00<<16)|$000,(a0)+

* Met � $000 la partie faible des composantes couleurs
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l #(bplcon3<<16)|($2202),d7
	bsr.s Build_Line
	move.l #(bplcon3<<16)|($a202),d7
	bsr.s Build_Line

** on arrive � la partie suivante par un COP_SKIP sur un pointeur coplist
	moveq #NB_LIGNES/2-1,d6
	move.l #$4d01fffe,d5
Build_All
	move.l #(bplcon3<<16)|($2002),d7	commence � la palette 1
	bsr.s Build_Line
	move.l d5,(a0)+				met le wait
	add.l #PIXEL_SIZE_Y<<24,d5
	move.l #(bplcon4<<16)|($0000),(a0)+	utilise les palettes 0-3

	move.l #(bplcon3<<16)|($a002),d7	commence � la palette 5
	bsr.s Build_Line
	move.l d5,(a0)+				met le wait
	add.l #PIXEL_SIZE_Y<<24,d5
	move.l #(bplcon4<<16)|($8000),(a0)+	utilise les palettes 4-7

	dbf d6,Build_All

	move.l #$fffffffe,(a0)+
	rts

Build_Line
	moveq #3-1,d4
Build_Part
	move.l d7,(a0)+				met le bplcon3
	moveq #32-1,d0				32 couleurs par parties
	move.l #color00<<16,d1
Build_Colors
	move.l d1,(a0)+				met le MOVE
	add.l #2<<16,d1
	dbf d0,Build_Colors

	add.w #$2000,d7				partie suivante
	dbf d4,Build_Part
	rts






*********************************************************************************
*                        Construction de la coplist vide                        *
*   -->	a5=_Tmap_DataBase                                                            *
*********************************************************************************
Build_Org_Coplist
	move.l Log_Coplist(a5),a0
	lea COP_SKIP+2(a0),a0
	lea org_coplist,a1
	lea Back_Texture,a2
	lea 256*2(a2),a3
	move.w #NB_LIGNES-1,d0
	moveq #0,d2
Build_Org
	bsr.s Transmute
	bsr.s Transmute
	bsr.s Transmute

	move.w (a0),(a1)+			sauve le wait
	move.w 4(a0),(a1)+			sauve le bplcon4
	addq.l #8,a0

	dbf d0,Build_Org
	rts

Transmute
	move.w (a0),(a1)+			sauve le move bplcon3
	moveq #32-1,d1
.trans
	move.b (a3)+,d2
	move.w (a2,d2.w*2),(a1)+		sauve la couleur
	dbf d1,.trans
	lea (1+32)*4(a0),a0
	rts



*********************************************************************************
*	Construction des textures � partir des Chunky et des palettes		*
*   -->	a5=_Tmap_DataBase								*
*********************************************************************************
Build_Textures
	movem.l a5/a6,-(sp)

	lea Textures_space,a0
	move.l a0,Textures(a5)

	lea Bitmap_Textures(pc),a1

	moveq #NB_TEXTURES,d0
	bra.s .start_build_all
.build_all
	move.w (a1)+,d1				lit le nombre de bitplans

* recherche le pointeur sur la palette
	move.w d1,d2
	mulu.w #TEXTURE_BITPLAN_SIZE,d2
	lea (a1,d2.w),a2			pointe les couleurs

* recherche la taille d'une ligne de texture
	move.w d1,d2
	mulu.w #TEXTURE_BITPLAN_LINE_SIZE,d2
	move.l d2,a4

*************************************************
* OCCUPATION DES REGISTRES:			*
* d0=Compteur du nombre de textures		*
* d1=Nb de bitplan de la texture en cours	*
* a0=Ptr destination de la texture		*
* a1=Ptr source de la texture			*
* a2=Ptr table des couleurs de la texture	*
* a3=Abscisse du point en cours			*
* a4=Taille d'une ligne compl�te de la texture	*
*************************************************
* boucle pour convertir sur les Y
	bra.s .start_convert_y
.loop_convert_y
	sub.l a3,a3				commence � la position 0
	bra.s .start_convert_x
.loop_convert_x
	move.w a3,d5				recherche le bit
	lsr.w #3,d5				numero de l'octet
	move.w a3,d4
	not.w d4
	and.b #$7,d4				numero du bit

	lea (a1,d5.w),a5			pointe l'octet
	moveq #0,d2
	moveq #0,d3
	bra.s .start_read_pixel
.loop_read_pixel
	btst d4,(a5)				bit � 1 ?
	beq.s .clear_bit
.set_bit
	bset d3,d2				met le bit
.clear_bit
	lea TEXTURE_BITPLAN_LINE_SIZE(a5),a5	bitplan suivant
	addq.w #1,d3
.start_read_pixel
	cmp.w d1,d3
	bne.s .loop_read_pixel

* cherche la couleur elle m�me
	move.w (a2,d2.w*2),d2			sauve le premier point

	move.w d2,(a0)+
	bsr.s Make_Shade

	addq.w #1,a3
.start_convert_x
	cmp.w #TEXTURE_X,a3
	bne.s .loop_convert_x

	add.l a4,a1				ligne suivante
.start_convert_y
	cmp.l a1,a2				fini ?
	bne.s .loop_convert_y

	moveq #0,d5				passe � la texture suivante
	bset d1,d5				=> saute la table des
	lea (a1,d5.w*2),a1			couleurs

	add.l #TEXTURE_SIZE*(TEXTURE_SHADE-1),a0
.start_build_all
	dbf d0,.build_all

	movem.l (sp)+,a5/a6
	rts



* fabrication des autres textures shad�es
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*   -->	d2=Couleurs
Make_Shade
	lea TEXTURE_SIZE-2(a0),a5		-2 car (a0)+
	moveq #TEXTURE_SHADE-1-1,d3
	lea Shade_Value(pc),a6
.build_shade
* on fait gaffe � ne pas shader an dessous de la valeur
* $1 pour une composante sauf si elle y est d�ja
	move.w d2,d5
	and.w #$f00,d5				shade le rouge
	move.w (a6),d6
	move.w #$100,d7				d7=$100
	bsr.s Shade
.skip_red
	move.w d5,d4

	move.w d2,d5				shade le vert
	and.w #$0f0,d5
	move.w (a6),d6
	lsr.w #4,d7				d7=$010
	bsr.s Shade
.skip_green
	or.w d5,d4

	move.w d2,d5
	and.w #$00f,d5
	move.w (a6)+,d6
	lsr.w #4,d7				d7=$001
	bsr.s Shade
.skip_blue
	or.w d5,d4

.skip
	move.w d4,(a5)
	lea TEXTURE_SIZE(a5),a5
	move.w d4,d2
	dbf d3,.build_shade
	rts

Shade
	bra.s .start
.loop
	cmp.w d7,d5
	ble.s .skip
	sub.w d7,d5
.start
	dbf d6,.loop	
.skip
	rts

Shade_Value
	dc.w 1
	dc.w 1
	dc.w 1
	dc.w 2
	dc.w 2
	dc.w 3
	dc.w 4

	IFNE 0
	dc.w 1
	dc.w 1
	dc.w 2
	dc.w 1
	dc.w 1
	dc.w 2
	dc.w 1
	ENDC



*********************************************************************************
*		Construction de la map du laby avec les textures		*
*   -->	a5=_Tmap_DataBase								*
*********************************************************************************
Build_Laby_Texture
	lea Laby_Texture_space,a0
	move.l a0,Laby_Texture(a5)

	lea Packed_Laby+Laby_Data(pc),a1
	move.l Textures(a5),a2
* on se positionne au milieu de la texture car le shading
* utilise un mot sign� lors de l'adressage: lea $xxxx(an),an
	lea TEXTURE_X*TEXTURE_Y*2*(TEXTURE_SHADE/2)(a2),a2

	moveq #LABY_Y-1,d0
.loop_Y
	moveq #LABY_X-1,d1
.loop_X
	moveq #4-1,d2
	move.w (a1)+,d3				lit le contenu d'une case
.loop_case
	move.w d3,d4				convertit le numero de la texture en un
	and.l #$f,d4				pointeur
	beq.s .no_texture
	subq.w #1,d4
	mulu.l #TEXTURE_X*TEXTURE_Y*2*TEXTURE_SHADE,d4
	lea (a2,d4.l),a3
	move.l a3,(a0)+
	lsr.w #4,d3
	dbf d2,.loop_case
	dbf d1,.loop_X
	dbf d0,.loop_Y
	rts
.no_texture
	clr.l (a0)+
	lsr.w #4,d3
	dbf d2,.loop_case
	dbf d1,.loop_X
	dbf d0,.loop_Y
	rts



*********************************************************************************
*                     Construction de la Table_Screen_Offset                    *
*   -->	a5=_Tmap_DataBase                                                            *
*********************************************************************************
Build_Table_Screen_Offset
	lea Table_Screen_Offset_space,a0	pour la Log_Table_Screen_Offset
	lea NB_COLONNES*4(a0),a1		pour la Phy_Table_Screen_Offset
	lea NB_COLONNES*4(a1),a2
	move.l a0,Log_Table_Screen_Offset(a5)
	move.l a1,Tmp_Table_Screen_Offset(a5)
	move.l a2,Phy_Table_Screen_Offset(a5)

	move.l Log_Coplist(a5),a4
	lea COP_SKIP+COP_SIZE_X*(NB_LIGNES/2)(a4),a4

	moveq #4+2,d0				bplcon3/move
	bsr.s Create_Table_Offset
	bsr Create_Table_Offset
Create_Table_Offset
	moveq #32-1,d1
Loop_Create_Table_Offset
	moveq #0,d2
	move.w d0,d2
	add.l a4,d2
	move.l d2,(a0)+
	add.l #COP_SIZE,d2
	move.l d2,(a1)+
	add.l #COP_SIZE,d2
	move.l d2,(a2)+

	addq.w #4,d0
	dbf d1,Loop_Create_Table_Offset
	addq.w #4,d0
	rts



*********************************************************************************
*                        Construction de la table de ZOOM                       *
*   -->	a5=_Tmap_DataBase                                                            *
*********************************************************************************
Build_Table_Zoom
	lea Table_Zoom_Offset(a5),a0
	lea Table_Zoom(a5),a1
	lea Table_Shade(pc),a2
	lea TEXTURE_X*TEXTURE_Y*2*(TEXTURE_SHADE/2),a3

	move.l a1,a4				JUSTE POUR CONNAITRE LA TAILLE DE LA TABLE
	moveq #1,d0
.For_H
	move.w #NB_LIGNES,d1
	sub.w d0,d1
	asr.w #1,d1

	moveq #0,d2
	tst.w d1
	bge.s .ok_abs
	move.w d1,d2
	neg.w d2
.ok_abs
	mulu.w #TEXTURE_Y,d2
	divu.w d0,d2

	moveq #0,d3

* G�naration de la table de saut pour chaque zoom:  bra.l d32
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.l a1,d4
	sub.l a0,d4
	subq.l #2,d4
	move.w #$60ff,(a0)+			bra.l ???
	move.l d4,(a0)+				bra.l patator
	addq.l #2,a0				multiple de 8 !!!

* Shading de texture:  lea d16(an),an
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	cmp.w (a2),d0
	blt.s .no_next
	sub.w #TEXTURE_X*TEXTURE_Y*2,a3
	addq.w #2,a2
.no_next
* lea $xxxx(src_reg),src_reg
	move.w #%0100000111101000|SRC_REG|(SRC_REG<<8),(a1)+
	move.w a3,(a1)+


* Boucle qui sert � fabriquer du code pour zoomer une colonne
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	moveq #0,d4
.For_A
	tst.w d1
	blt.s .out_of_screen
	cmp.w #NB_LIGNES,d1
	bgt.s .out_of_screen			ANCIEN: bge

	move.w d2,d5
	move.w #TEXTURE_Y,d2
	mulu.w d4,d2
	divu.w d0,d2

	cmp.w d2,d5
	bne.s .not_equal
.equal
	addq.w #1,d3
	bra.s .out_of_screen
.not_equal
	bsr.s Generate_Code
	moveq #1,d3
.out_of_screen
	addq.w #1,d1
	addq.w #1,d4
	cmp.w d0,d4
	ble.s .For_A

	cmp.w d2,d5
	bne.s .no_more_generate
	move.w #NB_LIGNES,d1			ANCIEN -1
	bsr.s Generate_Code
.no_more_generate
	move.w #$4e75,(a1)+
	addq.w #1,d0
	cmp.w #NB_ZOOM,d0
	ble.s .For_H
	rts

* G�n�ration de code pour zoomer
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Generate_Code
	cmp.w #1,d3
	bne.s generate_several

* G�n�ration de code:  move.b d16(an),d16(am)
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
generate_single
	move.w #$3000|SRC_REG|(DEST_REG<<9)|$28|$140,d6
	tst.w d5
	bne.s .no_opt1
	and.w #~$28,d6
	or.w #$10,d6
.no_opt1
	cmp.w #1+(NB_LIGNES/2),d1
	bne.s .no_opt2
	and.w #~$140,d6
	or.w #$80,d6
.no_opt2
	move.w d6,(a1)+

	tst.w d5
	beq.s .opt1
	move.w d5,d6
	mulu.w #TEXTURE_X*2,d6
	move.w d6,(a1)+
.opt1
	cmp.w #1+(NB_LIGNES/2),d1
	beq.s .opt2
	move.w d1,d6
	sub.w #1+(NB_LIGNES/2),d6
	muls.w #COP_SIZE_X,d6
	move.w d6,(a1)+
.opt2
	rts

* G�n�ration de code:  move.b d16(an),dp
*		       REPT nb
*		       move.b dp,d16(am)
*		       ENDR
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
generate_several
	move.w #$3000|SRC_REG|(TEMP_REG<<9)|$28,d6
	tst.w d5
	bne.s .no_opt1
	and.w #~$28,d6
	or.w #$10,d6
.no_opt1
	move.w d6,(a1)+

	tst.w d5
	beq.s .opt1
	move.w d5,d6
	mulu.w #TEXTURE_X*2,d6
	move.w d6,(a1)+
.opt1
	addq.w #1,d1
	sub.w d3,d1

	moveq #1,d7
.For_T
	move.w #$3000|TEMP_REG|(DEST_REG<<9)|$140,d6
	cmp.w #1+NB_LIGNES/2,d1
	bne.s .no_opt2
	and.w #~$140,d6
	or.w #$80,d6
.no_opt2
	move.w d6,(a1)+

	cmp.w #1+(NB_LIGNES/2),d1
	beq.s .opt2
	move.w d1,d6
	sub.w #1+(NB_LIGNES/2),d6
	muls.w #COP_SIZE_X,d6
	move.w d6,(a1)+
.opt2
.Next_T
	addq.w #1,d1
	addq.w #1,d7
	cmp.w d3,d7
	ble.s .For_T
	subq.w #1,d1
	rts

Table_Shade
	IFNE 0
*texture #6
	dc.w NB_ZOOM-235
*texture #5
	dc.w NB_ZOOM-230
*texture #4
	dc.w NB_ZOOM-220
*texture #3
	dc.w NB_ZOOM-210
*texture #2
	dc.w NB_ZOOM-200
*texture #1
	dc.w NB_ZOOM-190
*texture #0
	dc.w NB_ZOOM+1
	ENDC

*texture #6
	dc.w NB_ZOOM-250
*texture #5
	dc.w NB_ZOOM-240
*texture #4
	dc.w NB_ZOOM-230
*texture #3
	dc.w NB_ZOOM-220
*texture #2
	dc.w NB_ZOOM-210
*texture #1
	dc.w NB_ZOOM-200
*texture #0
	dc.w NB_ZOOM+1


*********************************************************************************
*              Fabrication de la table de rotation de la grille                 *
*   -->	a5=_Tmap_DataBase								*
*********************************************************************************
Build_Table_Rotate
	lea Table_Sinus(pc),a0
	lea (Table_Rotate.l,a5),a1
	move.l a1,a4				JUSTE POUR CONNAITRE LA TAILLE DE LA TABLE...
	lea (Table_Rotate_Offset.l,a5),a2

	move.w #360-1,d7			resolution de 1� sur 360�
For_TETA
	clr.w (a1)				c'est le nombre de points dans la table
	lea 2(a1),a3				c'est l� kon stocke

	move.l a1,(a2)+				sauve l'adresse de la table

	move.w 90*2(a0),d0			choppe le   cos(TETA)*$7fff
	move.w (a0)+,d1				et le       sin(TETA)*$7fff
	


* fait le carr� en haut � gauche
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w #BEGIN_WALL,d3			Y
	moveq #0,d5
For_J_1
	move.w #-BEGIN_WALL,d2			X
	moveq #0,d4
For_I_1
	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)			calcule de X1,Y1 et X2,Y2
	movem.w d2/d3,-(sp)

	move.w d2,d4
	move.w d3,d5
;;;	move.w d2,d2				X1=X
	sub.w #WALL_SIZE,d3			Y1=Y-WALL_SIZE
	add.w #WALL_SIZE,d4			X2=X+WALL_SIZE
	sub.w #WALL_SIZE,d5			Y2=Y-WALL_SIZE
	addq.w #2,d6				NB=SUD
	bsr Make_Wall

	movem.w (sp),d2-d5
	add.w #WALL_SIZE,d2			X1=X+WALL_SIZE
	sub.w #WALL_SIZE,d3			Y1=Y-WALL_SIZE
	add.w #WALL_SIZE,d4			X2=X+WALL_SIZE
;;;	move.w d5,d5				Y2=Y
	subq.w #1,d6				NB=EST
	bsr Make_Wall

	addq.l #4,sp
	movem.w (sp)+,d2-d5/d7
Next_I_1
	add.w #WALL_SIZE,d2			X=X+WALL_SIZE
	addq.w #1,d4
	cmp.w #(BAK_SIZE-1)/2,d4
	ble.s For_I_1

* fabrication des murs NORD
	sub.w #WALL_SIZE,d2
	subq.w #1,d4

	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)
	move.w d2,d4
	move.w d3,d5
	sub.w #WALL_SIZE,d5
	addq.w #3,d6				NB=OUEST
	bsr Make_Wall
	movem.w (sp)+,d2-d5/d7	
	
Next_J_1
	sub.w #WALL_SIZE,d3			Y=Y-WALL_SIZE
	addq.w #1,d5
	cmp.w #(BAK_SIZE-1)/2,d5
	blt For_J_1



* fait le carr� en haut � droite
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w #BEGIN_WALL,d2			X
	moveq #BAK_SIZE-1,d4
For_I_2
	move.w #BEGIN_WALL,d3			Y
	moveq #0,d5
For_J_2
	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)			calcule de X1,Y1 et X2,Y2
	movem.w d2/d3,-(sp)

	move.w d2,d4
	move.w d3,d5
	sub.w #WALL_SIZE,d2			X1=X-WALL_SIZE
;;;	move.w d3,d3				Y1=Y
	sub.w #WALL_SIZE,d4			X2=X-WALL_SIZE
	sub.w #WALL_SIZE,d5			Y2=Y-WALL_SIZE
	addq.w #3,d6				NB=OUEST
	bsr Make_Wall

	movem.w (sp),d2-d5
	sub.w #WALL_SIZE,d2			X1=X-WALL_SIZE
	sub.w #WALL_SIZE,d3			Y1=Y-WALL_SIZE
;;;	move.w d4,d4				X2=X
	sub.w #WALL_SIZE,d5			Y2=Y-WALL_SIZE
	subq.w #1,d6				NB=SUD
	bsr Make_Wall

	addq.l #4,sp
	movem.w (sp)+,d2-d5/d7
Next_J_2
	sub.w #WALL_SIZE,d3			Y=Y-WALL_SIZE
	addq.w #1,d5
	cmp.w #(BAK_SIZE-1)/2,d5
	ble.s For_J_2

* fabrication des murs EST
	add.w #WALL_SIZE,d3
	subq.w #1,d5

	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)
	move.w d2,d4
	sub.w #WALL_SIZE,d4
	move.w d3,d5
;;;	addq.w #0,d6				NB=NORD
	bsr Make_Wall
	movem.w (sp)+,d2-d5/d7

Next_I_2
	sub.w #WALL_SIZE,d2			X=X-WALL_SIZE
	subq.w #1,d4
	cmp.w #(BAK_SIZE-1)/2,d4
	bgt For_I_2



* fait le carr� en bas � droite
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w #-BEGIN_WALL,d3			Y
	moveq #BAK_SIZE-1,d5
For_J_3
	move.w #BEGIN_WALL,d2			X
	moveq #BAK_SIZE-1,d4
For_I_3
	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)			calcule de X1,Y1 et X2,Y2
	movem.w d2/d3,-(sp)

	move.w d2,d4
	move.w d3,d5
;;;	move.w d2,d2				X1=X
	add.w #WALL_SIZE,d3			Y1=Y+WALL_SIZE
	sub.w #WALL_SIZE,d4			X2=X-WALL_SIZE
	add.w #WALL_SIZE,d5			Y2=Y+WALL_SIZE
;;;	addq.w #0,d6				NB=NORD
	bsr Make_Wall

	movem.w (sp),d2-d5
	sub.w #WALL_SIZE,d2			X1=X-WALL_SIZE
	add.w #WALL_SIZE,d3			Y1=Y+WALL_SIZE
	sub.w #WALL_SIZE,d4			X2=X-WALL_SIZE
;;;	move.w d5,d5				Y2=Y
	addq.w #3,d6				NB=OUEST
	bsr Make_Wall

	addq.l #4,sp
	movem.w (sp)+,d2-d5/d7
Next_I_3
	sub.w #WALL_SIZE,d2			X=X-WALL_SIZE
	subq.w #1,d4
	cmp.w #(BAK_SIZE-1)/2,d4
	bge.s For_I_3

* fabrique les murs SUD
	add.w #WALL_SIZE,d2
	addq.w #1,d4

	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)
	move.w d2,d4
	move.w d3,d5
	add.w #WALL_SIZE,d5
	addq.w #1,d6				NB=EST
	bsr Make_Wall
	movem.w (sp)+,d2-d5/d7

Next_J_3
	add.w #WALL_SIZE,d3			Y=Y+WALL_SIZE
	subq.w #1,d5
	cmp.w #(BAK_SIZE-1)/2,d5
	bgt For_J_3



* fait le carr� en bas � gauche
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	move.w #-BEGIN_WALL,d2			X
	moveq #0,d4
For_I_4
	move.w #-BEGIN_WALL,d3			Y
	moveq #BAK_SIZE-1,d5
For_J_4
	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)			calcule de X1,Y1 et X2,Y2
	movem.w d2/d3,-(sp)

	move.w d2,d4
	move.w d3,d5
	add.w #WALL_SIZE,d2			X1=X+WALL_SIZE
;;;	move.w d3,d3				Y1=Y
	add.w #WALL_SIZE,d4			X2=X+WALL_SIZE
	add.w #WALL_SIZE,d5			Y2=Y+WALL_SIZE
	addq.w #1,d6				NB=EST
	bsr Make_Wall

	movem.w (sp),d2-d5
	add.w #WALL_SIZE,d2			X1=X+WALL_SIZE
	add.w #WALL_SIZE,d3			Y1=Y+WALL_SIZE
;;;	move.w d4,d4				X2=X
	add.w #WALL_SIZE,d5			Y2=Y+WALL_SIZE
	subq.w #1,d6				NB=NORD
	bsr Make_Wall

	addq.l #4,sp
	movem.w (sp)+,d2-d5/d7
Next_J_4
	add.w #WALL_SIZE,d3			Y=Y+WALL_SIZE
	subq.w #1,d5
	cmp.w #(BAK_SIZE-1)/2,d5
	bge.s For_J_4

* fabrique les murs OUEST
	sub.w #WALL_SIZE,d3
	addq.w #1,d5

	move.w d5,d6				numero de la case � roter
	mulu.w #LABY_X,d6
	add.w d4,d6
	add.w d6,d6
	add.w d6,d6

	movem.w d2-d5/d7,-(sp)			calcule de X1,Y1 et X2,Y2
	move.w d2,d4
	add.w #WALL_SIZE,d4
	move.w d3,d5
	addq.w #2,d6				NB=SUD
	bsr Make_Wall
	movem.w (sp)+,d2-d5/d7

Next_I_4
	add.w #WALL_SIZE,d2			X=X+WALL_SIZE
	addq.w #1,d4
	cmp.w #(BAK_SIZE-1)/2,d4
	blt For_I_4



* on trie maintenant les murs qui sont dans la table
* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	movem.l d0-d7/a0-a6,-(sp)
sort_element
	move.l a1,a0				ptr sur �l�ments
	move.w (a0)+,d0				nb d'�l�ments
	subq.w #1,d0				� cause du dbf

big_loop_sort_element
	subq.w #1,d0				on trie tjs sur N+1
	blt.s end_sort
	move.w d0,d1				nb d'�l�ment � trier
	move.l a0,a1				*element
	moveq #0,d2				la marque
loop_sort_element
	move.w Coord_X1(a1),d3			barycentreX*2 du mur 1
	add.w Coord_X2(a1),d3
	move.w Coord_Y1(a1),d4			barycentreY*2 du mur 1
	add.w Coord_Y2(a1),d4
	muls.w d3,d3				X^2
	muls.w d4,d4				Y^2
	add.l d4,d3				X^2+Y^2

	lea Rotate_SIZEOF(a1),a1
loop_sort_element_second
	move.w Coord_X1(a1),d5			barycentreX*2 du mur 2
	add.w Coord_X2(a1),d5
	move.w Coord_Y1(a1),d6			barycentreY*2 du mur 2
	add.w Coord_Y2(a1),d6
	muls.w d5,d5				X^2
	muls.w d6,d6				Y^2
	add.l d6,d5				X^2+Y^2

	cmp.l d3,d5
	bge.s element_ok
swap_element
	move.w -Rotate_SIZEOF+CaseOffset(a1),d5	echange les WallNumber
	move.w CaseOffset(a1),-Rotate_SIZEOF+CaseOffset(a1)
	move.w d5,CaseOffset(a1)

	move.l -Rotate_SIZEOF+Coord_X1(a1),d5		echange les X1 et Y1
	move.l Coord_X1(a1),-Rotate_SIZEOF+Coord_X1(a1)
	move.l d5,Coord_X1(a1)

	move.l -Rotate_SIZEOF+Coord_X2(a1),d5		echange les X2 et Y2
	move.l Coord_X2(a1),-Rotate_SIZEOF+Coord_X2(a1)
	move.l d5,Coord_X2(a1)

	lea Rotate_SIZEOF(a1),a1
	addq.w #1,d2				signale le changement
	dbf d1,loop_sort_element_second
	bra.s big_loop_sort_element
element_ok
	dbf d1,loop_sort_element
	tst.w d2
	bne.s big_loop_sort_element
end_sort
	movem.l (sp)+,d0-d7/a0-a6



Next_TETA
	move.l a3,a1				table suivante
	dbf d7,For_TETA
	rts


* calcule les murs
* ~~~~~~~~~~~~~~~~
*	d0=Cos(Teta)
*	d1=Sin(Teta)
*	d2=X1
*	d3=Y1
*	d4=X2
*	d5=Y2
*	d6=# de la case
Make_Wall
	movem.w d2-d7,-(sp)

	muls.w d0,d2				X1*Cos(TETA)
	muls.w d1,d3				Y1*Sin(TETA)
	sub.l d3,d2				NX1=X1*Cos(TETA)-Y1*Sin(TETA)
	add.l d2,d2
	swap d2

	movem.w (sp)+,d3/d4
	muls.w d1,d3				X1*Sin(TETA)
	muls.w d0,d4				Y1*Cos(TETA)
	add.l d4,d3				NY1=X1*Sin(TETA)+Y1*Cos(TETA)
	add.l d3,d3
	swap d3

	movem.w (sp),d4/d5
	muls.w d0,d4				X2*Cos(TETA)
	muls.w d1,d5				Y2*Sin(TETA)
	sub.l d5,d4				NX2=X2*Cos(TETA)-Y2*Sin(TETA)
	add.l d4,d4
	swap d4

	movem.w (sp)+,d5/d6
	muls.w d1,d5				Y2*Sin(TETA)
	muls.w d0,d6				X2*Cos(TETA)
	add.l d6,d5				NY2=X2*Sin(TETA)+Y2*Cos(TETA)
	add.l d5,d5
	swap d5

	move.w (sp)+,d6				r�cup�re le num�ro de la case

	tst.w d3				si ((NY1>0) or (NY2>0)) alors c'est visible
	bgt.s .wall_visible
	tst.w d5
	ble.s .wall_unvisible
.wall_visible

	cmp.w d3,d5				cone de visiblilit� de 90 �
	bgt.s .chk2

	tst.w d2
	blt.s .chk2

.chk1
	move.w d2,d7
	bgt.s .ok1
	neg.w d7
.ok1
	sub.w #WALL_SIZE,d7
	cmp.w d3,d7
	bgt.s .wall_unvisible
	bra.s .ok
.chk2
	move.w d4,d7
	bgt.s .ok2
	neg.w d7
.ok2
	sub.w #WALL_SIZE,d7
	cmp.w d5,d7
	bgt.s .wall_unvisible

.ok
	add.w d6,d6				table de LONG
	add.w d6,d6
	move.w d6,(a3)+				sauve le # de la case
	lsr.w #2,d6

	move.w d2,(a3)+				X1
	move.w d3,(a3)+				Y1
	move.w d4,(a3)+				X2
	move.w d5,(a3)+				Y2

	addq.w #1,(a1)				et un mur en plus
.wall_unvisible
	move.w (sp)+,d7
	rts




*********************************************************************************
*                       Initialisation de l'observateur				*
*   -->	a5=_Tmap_DataBase                                                            *
*********************************************************************************
Init_Observateur
	move.w Packed_Laby+Laby_PosX(pc),d0	r�cup�re la position X
	mulu.w #WALL_SIZE,d0
	add.w #WALL_SIZE/2,d0
	move.w d0,PosX(a5)

	move.w Packed_Laby+Laby_PosY(pc),d0	r�cup�re la position Y
	mulu.w #WALL_SIZE,d0
	add.w #WALL_SIZE/2,d0
	move.w d0,PosY(a5)

	move.w Packed_Laby+Laby_Angle(pc),Angle(a5)	r�cup�re l'angle

	clr.w Angle_Speed(a5)
	clr.w Speed(a5)

	lea Start_Table_Player(pc),a0
	move.l a0,Table_Player(a5)
	move.b #1,Player_Timer(a5)
	st Player_On(a5)
	rts




*********************************************************************************
*			Initialisation des sprites				*
*   -->	a5=_Tmap_DataBase
*********************************************************************************
Init_Sprites
	move.l Log_Coplist(a5),a0
	lea 11*4+2(a0),a0			pointe les sprXpt
	move.l Tmp_Coplist(a5),a1
	lea 11*4+2(a1),a1
	move.l Phy_Coplist(a5),a2
	lea 11*4+2(a2),a2

* sprite 0
* ~~~~~~~~
	lea Bord_Gauche_Sprite,a3
	move.l a3,d0
	bsr install_spr

	moveq #63*2-2,d0			init la position de
	moveq #-2+$22,d1			Bord_Gauche_Sprite
	move.w #SCREEN_Y+4,d2
	bsr Compute_Sprite_Control
	move.w d0,(a3)
	move.w d3,8(a3)


* sprite 1
* ~~~~~~~~
	lea Bord_Haut1_Sprite,a3		avec Bord_Bas1
	move.l a3,d0
	bsr install_spr

	move.w #64*2-2+63*2,d0			init la position de
	moveq #-2+$22,d1			Bord_Haut1_Sprite
	moveq #2,d2
	bsr Compute_Sprite_Control
	move.w d0,(a3)
	move.w d3,8(a3)

	move.w #64*2-2+63*2,d0			init la position de
	move.w #SCREEN_Y+$22,d1			Bord_Bas1_Sprite
	moveq #2,d2
	bsr Compute_Sprite_Control
	move.w d0,Bord_Bas1_Sprite-Bord_Haut1_Sprite(a3)
	move.w d3,Bord_Bas1_Sprite-Bord_Haut1_Sprite+8(a3)

* sprite 2
* ~~~~~~~~
	lea Bord_Haut2_Sprite,a3		avec Bord_Bas2
	move.l a3,d0
	bsr.s install_spr

	move.w #64*4-2+63*2,d0			init la position de
	moveq #-2+$22,d1			Bord_Haut2_Sprite
	moveq #2,d2
	bsr.s Compute_Sprite_Control
	move.w d0,(a3)
	move.w d3,8(a3)

	move.w #64*4-2+63*2,d0			init la position de
	move.w #SCREEN_Y+$22,d1			Bord_Bas2_Sprite
	moveq #2,d2
	bsr.s Compute_Sprite_Control
	move.w d0,Bord_Bas2_Sprite-Bord_Haut2_Sprite(a3)
	move.w d3,Bord_Bas2_Sprite-Bord_Haut2_Sprite+8(a3)

* sprite 3
* ~~~~~~~~
	lea Bord_Droit_Sprite,a3
	move.l a3,d0
	bsr.s install_spr

	move.w #64*6-4+63*2,d0			init la position de
	moveq #-2+$22,d1			Bord_Droit_Sprite
	move.w #SCREEN_Y+4,d2
	bsr.s Compute_Sprite_Control
	move.w d0,(a3)
	move.w d3,8(a3)


* sprites 4/5/6/7
* ~~~~~~~~~~~~~~~
	REPT 4
	lea Blank_Sprite,a3
	move.l a3,d0				sprites inutiles
	bsr.s install_spr
	ENDR
	rts

install_spr
	move.w d0,4(a0)
	move.w d0,4(a1)
	move.w d0,4(a2)
	swap d0
	move.w d0,(a0)
	move.w d0,(a1)
	move.w d0,(a2)
	addq.l #8,a0
	addq.l #8,a1
	addq.l #8,a2
	rts




*********************************************************************************
*                       CALCUL DES MOTS DE CONTROL D'UN SPRITE			*
* en entr�e: d0=PosX								*
*            d1=PosY								*
*            d2=Hauteur								*
*										*
* en sortie: d0=1er mot de controle						*
*            d3=2�me mot de controle						*
*********************************************************************************
Compute_Sprite_Control
	moveq #0,d3
	add.w #$80*2-2,d0			recentre sur les X
	move.w d0,d5
	lsr.w #2,d0
	bcc.s put_sprite_pas_carryX
	moveq #1,d3
put_sprite_pas_carryX
	add.w #$2b,d1				recentre sur les Y
	move.w d1,d4
	lsl.w #8,d1
	bcc.s put_sprite_pas_carryY1
	or.w #4,d3
put_sprite_pas_carryY1
	or.w d1,d0
	add.w d2,d4
	lsl.w #8,d4
	bcc.s put_sprite_pas_carryY2
	or.w #2,d3
put_sprite_pas_carryY2
	or.w d4,d3
	and.w #$1,d5
	lsl.w #4,d5
	or.w d5,d3
	rts








*********************************************************************************
*			Toutes les constantes de la demo			*
*********************************************************************************
Start_Table_Player
	incbin "Record_toto.RAW"

	even
Table_Sinus
Table_Cosinus=Table_Sinus+90*2
	incbin "Table_Sinus.RAW"

Packed_Laby
	incbin "Laby.RAW"

Bitmap_Textures
	LOAD_TEXTURE_BMP 5,Vache1
	LOAD_TEXTURE_BMP 5,Vache2
	LOAD_TEXTURE_BMP 4,Cochon

Back_Texture
	LOAD_TEXTURE_CHK Back



	ROUND
	section outch,data_c


Bord_Gauche_Sprite
	dc.l 0,0,0,0
	dc.l $ffffffff,$ffffffff,0,0
;;	dc.l $7fffffff,$ffffffff,0,0
	dc.l $ffffffff,$ffffffff,0,0
	REPT SCREEN_Y
	dc.l $c0000000,0,0,0
	ENDR
	dc.l $ffffffff,$ffffffff,0,0
;;	dc.l $7fffffff,$ffffffff,0,0
	dc.l $ffffffff,$ffffffff,0,0
Blank_Sprite
	dc.l 0,0,0,0

Bord_Haut1_Sprite
	dc.l 0,0,0,0
	dc.l $ffffffff,$ffffffff,0,0
	dc.l $ffffffff,$ffffffff,0,0
Bord_Bas1_Sprite
	dc.l 0,0,0,0
	dc.l $ffffffff,$ffffffff,0,0
	dc.l $ffffffff,$ffffffff,0,0
	dc.l 0,0,0,0

Bord_Haut2_Sprite
	dc.l 0,0,0,0
	dc.l $ffffffff,$ffffffff,0,0
	dc.l $ffffffff,$ffffffff,0,0
Bord_Bas2_Sprite
	dc.l 0,0,0,0
	dc.l $ffffffff,$ffffffff,0,0
	dc.l $ffffffff,$ffffffff,0,0
	dc.l 0,0,0,0

Bord_Droit_Sprite
	dc.l 0,0,0,0
	dc.l $f0000000,0,0,0
;;	dc.l $e0000000,0,0,0
	dc.l $f0000000,0,0,0
	REPT SCREEN_Y
	dc.l $30000000,0,0,0
	ENDR
	dc.l $f0000000,0,0,0
;;	dc.l $e0000000,0,0,0
	dc.l $f0000000,0,0,0
	dc.l 0,0,0,0




*********************************************************************************
*                         Toutes les datas du programme                         *
*********************************************************************************
	ROUND
	section mes_daaaatas,bss
	rsset -DATA_OFFSET
_Tmap_DataBase_Struct	rs.b 0
Tmap_Compteur		rs.w 1
Log_Coplist		rs.l 1
Tmp_Coplist		rs.l 1
Phy_Coplist		rs.l 1
Log_Table_Screen_Offset	rs.l 1
Tmp_Table_Screen_Offset	rs.l 1
Phy_Table_Screen_Offset	rs.l 1
Screen			rs.l 1
PosX			rs.l 1
PosY			rs.l 1
Speed			rs.w 1
Angle			rs.w 1
Angle_Speed		rs.w 1
Flip_Flag		rs.b 1
Tmap_End		rs.b 1

Table_Player		rs.l 1
Player_Joy		rs.w 1
Player_Timer		rs.b 1
Player_On		rs.b 1

Laby_Texture		rs.l 1
Textures		rs.l 1
Table_Zoom_Offset	rs.l NB_ZOOM*2
Table_Zoom		rs.b 79656			cf MONAM !
Table_Rotate_Offset	rs.l 360
Table_Rotate		rs.b 235200			cf MONAM !
_Tmap_DataBase_SIZEOF=__RS-_Tmap_DataBase_Struct

_Tmap_DataBase=*+DATA_OFFSET
	ds.b _Tmap_DataBase_SIZEOF

Table_Screen_Offset_space
	ds.l NB_COLONNES*3

Laby_Texture_space
	ds.l LABY_X*LABY_Y*4

Textures_space
	ds.w TEXTURE_X*TEXTURE_Y*NB_TEXTURES*TEXTURE_SHADE



	ROUND
	section pompom,bss_c

Screen_space
	ds.b SCREEN_WIDTH*SCREEN_DEPTH
Coplist_space
	ds.b COP_SIZE*3
org_coplist
	ds.w (COP_SIZE_X/4)*NB_LIGNES





***************
* end of file *
***************
