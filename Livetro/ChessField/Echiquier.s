
*				Echiquier en 3d
*				---------------

	XREF SCREEN_AREA
	XREF MT_MUSIC
	XDEF CHESSFIELD

SCREEN_WIDTH=352
SCREEN_HEIGHT=272
LINE=226
NB=178

	incdir "dh1:Livetro/" "dh1:Livetro/ChessField/"
	include "asm:sources/registers.i"

	section gfae,code
CHESSFIELD
	lea data_base(pc),a5
	lea $dff000,a6

	move.l #SCREEN_AREA+(SCREEN_WIDTH/8)*SCREEN_HEIGHT*2,log_screen-data_base(a5)
	move.l #SCREEN_AREA,phy_screen-data_base(a5)

	movem.l log_screen(pc),d0-d1
	move.l #(SCREEN_WIDTH/8)*SCREEN_HEIGHT,d2
	lea coplist1+2,a0
	lea coplist2+2,a1
	moveq #2-1,d3
put_ptr
	move.w d0,4(a0)
	move.w d1,4(a1)
	swap d0
	swap d1
	move.w d0,(a0)
	move.w d1,(a1)
	swap d0
	swap d1
	add.l d2,d0
	add.l d2,d1
	addq.l #8,a0
	addq.l #8,a1
	dbf d3,put_ptr

	move.l #coplist2,cop1lc(a6)
	clr.w copjmp1(a6)
	move.l #zik_vbl,$6c.w
tst_zik_vbl
	tst.w waiting-data_base(a5)
	bne.s tst_zik_vbl

	move.l #vbl,$6c.w

exit_wait
	tst.w time-data_base(a5)
	bgt.s exit_wait

	rts

zik_vbl
	movem.l d0-d7/a0-a6,-(sp)
	jsr MT_MUSIC
	subq.w #1,waiting
	movem.l (sp)+,d0-d7/a0-a6
	move.w #$0020,$dff000+intreq
	rte

vbl
	bsr Clear_Screen
	jsr MT_MUSIC
	lea data_base(pc),a5
	lea $dff000,a6

	bsr Compute_Matrix			calcule la matrice de rotation
	bsr Compute_Dots			points 3d -> 2d
	bsr Display_ChessField			affiche l'�chiquier

	move.w nb_right1(pc),d7
	move.l log_screen(pc),a1
	lea right_point1(pc),a2
	bsr Display_Right_Line			corrige l'affichage
	move.w nb_right2(pc),d7
	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT(a1),a1
	lea right_point2(pc),a2
	bsr Display_Right_Line			corrige l'affichage
	bsr Fill_ChessField			rempli l'�chiquier



********************************************************************************
*************                                                       ************
*************  AUGMENTATION DES ANGLES POUR LA MATRICE DE ROTATION  ************
*************                                                       ************
********************************************************************************
Incrize_Angles
	lea Alpha(pc),a0
do_Alpha
	addq.w #6,(a0)+
	cmp.w #1440,-2(a0)
	blt.s do_Teta
	sub.w #1440,-2(a0)
do_Teta
	addq.w #4,(a0)+
	cmp.w #1440,-2(a0)
	blt.s do_Phi
	sub.w #1440,-2(a0)
do_Phi
	addq.w #4,(a0)
	cmp.w #1440,(a0)
	blt.s Inc_End
	sub.w #1440,(a0)
Inc_End
	


********************************************************************************
*************                                                       ************
*************           TEST DE VISIBILITE DU CHESSFIELD            ************
*************                                                       ************
********************************************************************************
Test_Visible
	clr.w What_Visible-data_base(a5)
Test_Visible_Alpha
	cmp.w #90*4,Alpha-data_base(a5)
	ble.s Test_Visible_Teta
	cmp.w #270*4,Alpha-data_base(a5)
	bge.s Test_visible_Teta
	not.w What_Visible-data_base(a5)
Test_Visible_Teta
	cmp.w #90*4,Teta-data_base(a5)
	ble.s Test_Visible_End
	cmp.w #270*4,Teta-data_base(a5)
	bge.s Test_visible_End
	not.w What_Visible-data_base(a5)
Test_Visible_End
	subq.w #1,time-data_base(a5)
	move.l Zoom_Ptr(pc),a0
	move.w (a0)+,Zoom-data_base(a5)
	move.l a0,Zoom_Ptr-data_base(a5)

	movem.l log_screen(pc),a0-a3		echange les ptr videos
	exg a0,a1
	exg a2,a3
	movem.l a0-a3,log_screen-data_base(a5)
	move.l a3,cop1lc(a6)
	move.w #$0020,intreq(a6)
	rte



********************************************************************************
************************  EFFACAGE DE L'ECRAN DE TRAVAIL  **********************
************************                                  **********************
************************      ET ECHANGE DES COPLISTS     **********************
********************************************************************************
Clear_Screen
	move.l log_screen(pc),bltdpt(a6)	efface le log_screen
	move.l #$1000000,bltcon0(a6)
	clr.w bltdmod(a6)
	tst.w What_Visible-data_base(a5)
	beq.s Clear_ChessField
Clear_Cuted
	move.w #(SCREEN_HEIGHT*2-LINE)<<6+(SCREEN_WIDTH/16),bltsize(a6)
	move.w #$2200,set_nb_bpl-coplist1(a2)
	move.w #$a86,col1-coplist1(a2)
	move.w #$ca8,col2-coplist1(a2)
	rts
Clear_ChessField
	move.w #(SCREEN_HEIGHT)<<6+(SCREEN_WIDTH/16),bltsize(a6)
	move.w #$1200,set_nb_bpl-coplist1(a2)
	move.w #$fff,col1-coplist1(a2)
	clr.w col2-coplist1(a2)
	rts

data_base
waiting
	dc.w 20
time
	dc.w 360
log_screen
	dc.l 0
phy_screen
	dc.l 0
log_coplist
	dc.l coplist1
phy_coplist
	dc.l coplist2



********************************************************************************
*********************                                    ***********************
*********************  CALCUL DE LA MATRICE DE ROTATION  ***********************
*********************                                    ***********************
********************************************************************************
cosalpha equr d0				qq equr pour se simplifier
sinalpha equr d1				la lecture
costeta  equr d2
sinteta  equr d3
cosphi   equr d4
sinphi   equr d5

compute_matrix
	lea table_cosinus(pc),a0
	lea table_sinus(pc),a1

	movem.w Alpha(pc),d0-d2			va chercher les angles

	move.w 0(a1,d2.w),sinphi		sinus phi
	move.w 0(a0,d2.w),cosphi		cosinus phi

	move.w 0(a1,d1.w),sinteta		sinus teta
	move.w 0(a0,d1.w),costeta		cosinus teta

	move.w 0(a1,d0.w),sinalpha		sinus alpha
	move.w 0(a0,d0.w),cosalpha		cosinus alpha

	lea matrix(pc),a0

	move.w costeta,d6
	muls cosphi,d6				cos(teta) * cos(phi)
	swap d6
	move.w d6,(a0)

	move.w costeta,d6
	muls sinphi,d6				cos(teta) * sin(phi)
	swap d6
	move.w d6,2(a0)

	move.w sinalpha,d6
	muls sinteta,d6				sin(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a3

	muls cosphi,d6				sin(alpha)*sin(teta)*cos(phi)
	move.w cosalpha,d7
	muls sinphi,d7				cos(alpha) * sin(phi)
	sub.l d7,d6
	swap d6
	move.w d6,4(a0)

	move.w a3,d6
	muls sinphi,d6				sin(alpha)*sin(teta)*sin(phi)
	move.w cosalpha,d7
	muls cosphi,d7				cos(alpha) * cos(phi)
	add.l d7,d6
	swap d6
	move.w d6,6(a0)

	move.w cosalpha,d6
	muls sinteta,d6				cos(alpha) * sin(teta)
	swap d6
	rol.l #1,d6
	move.w d6,a3

	muls cosphi,d6				cos(alpha)*sin(teta)*cos(phi)
	move.w sinalpha,d7
	muls sinphi,d7				sin(alpha) * sin(phi)
	add.l d7,d6
	swap d6
	move.w d6,8(a0)

	move.w a3,d6
	muls sinphi,d6				cos(alpha)*sin(teta)*sin(phi)
	move.w sinalpha,d7
	muls cosphi,d7				sin(alpha) * cos(phi)
	sub.l d7,d6
	swap d6
	move.w d6,10(a0)		

	rts

matrix	dcb.w 2*3,0				la matrice de rotation
Alpha	dc.w 0
Teta	dc.w 0
Phi	dc.w 0
Zoom	dc.w 725
Zoom_Ptr
	dc.l Zoom_Table
What_Visible
	dc.w 0
Table_Cosinus
	incbin "table_cosinus.dat"
Table_Sinus=Table_Cosinus+180*2
Zoom_Table
Z set 725
	rept 120
	dc.w Z
Z set Z+4
	endr
	dcb.w 121,Z
	rept 120
Z set Z-4
	dc.w Z
	endr
	


********************************************************************************
*************                                                        ***********
*************  TRANSFORMATIONS DES COORDONNEES 3D EN COORDONNEES 2D  ***********
*************                                                        ***********
********************************************************************************
Compute_Dots
	tst.w What_Visible-data_base(a5)
	bne.s Compute_Dots_Cuted
Compute_Dots_ChessField
	lea dots_3d_ChessField(pc),a0
	moveq #18-1,d0
	bra.s Compute_All_Dots

Compute_Dots_Cuted
	lea dots_3d_Cuted(pc),a0		pointe les points 3d originaux
	moveq #6-1,d0				6 points � roter
Compute_All_Dots
	lea dots_2d(pc),a1			pointe les points 2d
	move.w Zoom(pc),d6			le zoom
	moveq #9,d7				valeur du shift de D

loop_compute_dots
	movem.w (a0),d1-d2			coord 3d du point
	muls matrix(pc),d1
	muls matrix+2(pc),d2
	add.l d2,d1
	swap d1
	ext.l d1
	lsl.l d7,d1				X=X*D

	movem.w (a0),d2-d3			coord 3d du point
	muls matrix+4(pc),d2
	muls matrix+6(pc),d3
	add.l d3,d2
	swap d2					Y
	ext.l d2
	lsl.l d7,d2				Y=Y*D

	movem.w (a0)+,d3-d4			coord 3d du point
	muls matrix+8(pc),d3
	muls matrix+10(pc),d4
	add.l d4,d3
	swap d3					Z
	add.w d6,d3				ajoute le zoom

	beq.s no_divs
	divs d3,d1				Xe=X*D/Z
	divs d3,d2				Ye=Y*D/Z
no_divs
	add.w #SCREEN_WIDTH/2,d1		recentre � l'�cran
	add.w #SCREEN_HEIGHT/2,d2
	move.w d1,(a1)+				sauve Xe,Ye
	move.w d2,(a1)+

	dbf d0,loop_compute_dots	
	rts



********************************************************************************
*************                                                       ************
*************                AFFICHAGE DU CHESSFIELD		    ************
*************                                                       ************
********************************************************************************
Display_ChessField
	tst.w What_Visible-data_base(a5)
	beq Display_Chess			ChessField devant si >0

Display_Cuted
	moveq #0,d0				efface tous les registres
	moveq #0,d1				car BLITTER + 68000
	moveq #0,d2
	moveq #0,d3
	moveq #0,d4
	moveq #0,d5
	moveq #0,d6
	moveq #0,d7
	move.l d0,a0
	move.l d0,a1
	move.l d0,a2
	move.l d0,a3
	move.l d0,a4
	move.l d0,a5	

	move.l log_screen(pc),a6
	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT*2(a6),a6

	rept NB
	movem.l d0-d7/a0-a5,-(a6)
	endr

	lea data_base(pc),a5
	lea $dff000,a6

DrawLine_Init
	btst #14,dmaconr(a6)
	bne.s DrawLine_Init

	moveq #SCREEN_WIDTH/8,d0
	move.w d0,bltcmod(a6)			\ largeur de l'image
	move.w d0,bltdmod(a6)			/
	moveq #-1,d0
	move.w d0,bltbdat(a6)			masque de la droite
	move.l d0,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point

	lea dots_2d(pc),a1
	move.l log_screen(pc),a2
	lea right_point1(pc),a3
	clr.w nb_right-data_base(a5)

	movem.w (a1),d0-d3
	bsr DrawLine
	movem.w 1*4(a1),d0-d3
	bsr DrawLine
	movem.w 2*4(a1),d0-d3
	bsr DrawLine
	movem.w 3*4(a1),d0-d1
	movem.w (a1),d2-d3
	bsr DrawLine
	move.w nb_right(pc),nb_right1-data_base(a5)

	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT(a2),a2
	lea right_point2(pc),a3
	clr.w nb_right-data_base(a5)
	movem.w 2*4(a1),d0-d3
	bsr DrawLine
	movem.w 3*4(a1),d0-d3
	bsr DrawLine
	movem.w 4*4(a1),d0-d3
	bsr DrawLine
	movem.w 5*4(a1),d0-d1
	movem.w 2*4(a1),d2-d3
	bsr DrawLine
	move.w nb_right(pc),nb_right2-data_base(a5)
	rts

Display_Chess
	btst #14,dmaconr(a6)
	bne.s Display_Chess

	moveq #SCREEN_WIDTH/8,d0
	move.w d0,bltcmod(a6)			\ largeur de l'image
	move.w d0,bltdmod(a6)			/
	moveq #-1,d0
	move.w d0,bltbdat(a6)			masque de la droite
	move.l d0,bltafwm(a6)			masque sur A
	move.w #$8000,bltadat(a6)		Style du point

	lea dots_2d(pc),a1
	move.l log_screen(pc),a2
	lea right_point1(pc),a3
	clr.w nb_right2-data_base(a5)
	clr.w nb_right-data_base(a5)

	movem.w 2*4(a1),d0-d1
	movem.w 12*4(a1),d2-d3
	bsr DrawLine
	movem.w 12*4(a1),d0-d3
	bsr DrawLine
	movem.w 13*4(a1),d0-d1
	movem.w 1*4(a1),d2-d3
	bsr DrawLine

	movem.w 4*4(a1),d0-d1
	movem.w 10*4(a1),d2-d3
	bsr DrawLine
	movem.w 10*4(a1),d0-d3
	bsr DrawLine
	movem.w 11*4(a1),d0-d1
	movem.w 3*4(a1),d2-d3
	bsr DrawLine

	movem.w (a1),d0-d3
	bsr DrawLine
	movem.w 2*4(a1),d0-d3
	bsr DrawLine
	movem.w 4*4(a1),d0-d3
	bsr DrawLine

	movem.w 5*4(a1),d0-d3
	bsr DrawLine
	movem.w 6*4(a1),d0-d1
	movem.w 17*4(a1),d2-d3
	bsr DrawLine
	movem.w 17*4(a1),d0-d1
	movem.w (a1),d2-d3
	bsr DrawLine

	movem.w 16*4(a1),d0-d1
	movem.w 7*4(a1),d2-d3
	bsr DrawLine
	movem.w 7*4(a1),d0-d3
	bsr DrawLine
	movem.w 8*4(a1),d0-d1
	movem.w 15*4(a1),d2-d3
	bsr DrawLine
	movem.w 15*4(a1),d0-d3
	bsr DrawLine
	move.w nb_right(pc),nb_right1-data_base(a5)
	rts



********************************************************************************
*************                                                       ************
*************           TRACE DE DROITES AVEC CLIPPING              ************
*************                                                       ************
********************************************************************************
DrawLine
*---------------------> on clippe la droite
	cmp.w d2,d0
	ble.s .x1_less_x2
	exg d0,d2
	exg d1,d3
.x1_less_x2
	cmp.w #SCREEN_WIDTH,d2
	blt.s .no_inter_X_max
	cmp.w #SCREEN_WIDTH,d0
	bge no_line

*---------------> clip suivant les X avec le bord droit ( Xmax )
	move.w #SCREEN_WIDTH-1,d4
	sub.w d2,d4				(D-X2)
	move.w d3,d5				sauve Y2
	sub.w d1,d3				(Y2-Y1)
	muls d4,d3				(Y2-Y1)*(D-X2)
	sub.w d0,d2				(X2-X1)
	divs d2,d3				(Y1-Y2)*(D-X2)/(X1-X2)
	add.w d5,d3				(Y1-Y2)*(D-X2)/(X1-X2)+Y2
	move.w #SCREEN_WIDTH-1,d2		X2=SCREEN_WIDTH-1

	move.w d3,(a3)+				sauve le Y clipp�
	addq.w #1,nb_right-data_base(a5)	inc le nb de right line

.no_inter_X_max
	tst.w d0
	bge.s .no_inter_X_min
	tst.w d2
	blt no_line

*---------------> clip suivant les X avec le bord gauche ( Xmin )
	sub.w d3,d1				(Y1-Y2)
	muls d2,d1				(Y1-Y2)*(X2-0)
	neg.l d1				(Y1-Y2)*(0-Y2)
	sub.w d2,d0				(X2-X1)
	divs d0,d1				(Y1-Y2)*(0-Y2)/(X2-X1)
	add.w d3,d1				Y1=(Y1-Y2)*(0-Y2)/(X2-X1)+Y2
	moveq #0,d0				X1=0

.no_inter_X_min
	cmp.w d3,d1
	ble.s .y1_less_y2
	exg d0,d2
	exg d1,d3
.y1_less_y2
	tst.w d1
	bge.s .no_inter_Y_min
	tst.w d3
	blt no_line	

*---------------> clip suivant les Y avec le haut ( Ymin )
	move.w d0,d4				sauve X1
	sub.w d2,d0				(X1-X2)
	muls d1,d0				(0-Y1)*(X2-X1)
	sub.w d3,d1				(Y1-Y2)
	neg.w d1				(Y2-Y1)
	divs d1,d0				(0-Y1)*(X2-X1)/(Y2-Y1)
	add.w d4,d0				(0-Y1)*(X2-X1)/(Y2-Y1)+X1
	moveq #0,d1				Y1=0

.no_inter_Y_min
	cmp.w #SCREEN_HEIGHT,d3
	blt.s .no_inter_Y_max
	cmp.w #SCREEN_HEIGHT,d1
	bge no_line

*---------------> clip suivant les Y avec le bas ( Ymax )
	move.w #SCREEN_HEIGHT-1,d4
	sub.w d1,d4				(D-Y1)
	sub.w d0,d2				(X2-X1)
	muls d4,d2				(D-Y1)*(X2-X1)
	sub.w d1,d3				(Y2-Y1)
	divs d3,d2				(D-Y1)*(X2-X1)/(Y2-Y1)
	add.w d0,d2				(D-Y1)*(X2-X1)/(Y2-Y1)+X1
	move.w #SCREEN_HEIGHT-1,d3

.no_inter_Y_max
*----------------------------> routine qui trace une droite 3d
	sub.w d0,d2				d2=deltaX
	sub.w d1,d3				d3=deltaY
	beq.s no_line
	subq.w #1,d3

	moveq #0,d4
	ror.w #4,d0				\
	move.b d0,d4				 > d0=d�calage
	and.w #$f000,d0				/

	add.w d4,d4				d4=adr en octets sur X
	add.w d1,d1				d1=d1*2 car table de mots
	add.w Table_Mulu(pc,d1.w),d4		d4=d1*Width+d4
	lea 0(a2,d4.w),a0			recherche 1er mot de la droite
	move.w d0,d4				sauvegarde du d�calage
	or.w #$0b4a,d4				minterm=$4a  EOR
.find_octant	
	moveq #0,d1
	tst.w d2
	bpl.s .X1_inf_X2
	neg.w d2
	moveq #4,d1
.X1_inf_X2
	cmp.w d2,d3
	bpl.s .DY_sup_DX
	or.b #16,d1
	bra.s .octant_found
.DY_sup_DX
	exg d2,d3
	add.b d1,d1
.octant_found

	addq.b #3,d1				LINE + ONEDOT
	or.w d0,d1				rajoute le d�calage
	
	add.w d3,d3				4*Pdelta
	add.w d3,d3
	add.w d2,d2				2*Gdelta

.wait
	btst #14,dmaconr(a6)
	bne.s .wait

	move.w d3,bltbmod(a6)
	sub.w d2,d3				4*Pdelta-2*Gdelta
	bge.s .no_SIGNFLAG
	or.w #$40,d1
.no_SIGNFLAG
	movem.w d1,bltcon1(a6)
	move.w d3,bltapt+2(a6)
	sub.w d2,d3				4*Pdelta-4*Gdelta
	move.w d3,bltamod(a6)

	move.w d4,bltcon0(a6)

	move.l a0,bltcpt(a6)			\ pointeur sur 1er mot droite
	move.l a0,bltdpt(a6)			/

	addq.w #1<<1,d2				(Gdelta+1)<<1
	lsl.w #5,d2				(Gdelta+1)<<6
	addq.w #2,d2				(Gdelta+1)<<6+2
	move.w d2,bltsize(a6)			tra�age de la droite
no_line
	rts

Table_Mulu
MuluCount set 0
	rept SCREEN_HEIGHT
	dc.w MuluCount*(SCREEN_WIDTH/8)
MuluCount set MuluCount+1
	endr



********************************************************************************
*************                                                       ************
*************    TRACE DES RIGHT LINES POUR CORRIGER L'AFFICHAGE    ************
*************    d7/a1/a2 initialis� en entr�e                      ************
********************************************************************************
Display_Right_Line
*---------------> on trie les right droites s'il le faut
	tst.w d7
	beq no_right_line

	move.w d7,d0
one_line_at_least
	subq.w #1,d0				� cause du dbf
big_loop_sort_right_coord
	subq.w #1,d0				on trie sur N+1
	blt.s sort_right_coord_end
	move.w d0,d1				nb d'�l�ment � trier
	move.l a2,a3				*element
	moveq #0,d2				la marque
loop_sort_right_coord
	move.w (a3)+,d3				coord1
loop_sort_right_coord_second
	cmp.w (a3),d3				coord1<=coord2 ?
	ble.s right_ok
	move.w (a3),-2(a3)			�change les coord
	move.w d3,(a3)+
	addq.w #1,d2				signale le changement
	dbf d1,loop_sort_right_coord_second
	bra.s big_loop_sort_right_coord
right_ok
	dbf d1,loop_sort_right_coord
	tst.w d2
	bne.s big_loop_sort_right_coord
sort_right_coord_end

*----------------------> on affiche les right line
	lsr.w #1,d7				divise par 2 car paires
	subq.w #1,d7				� cause du dbf
	lea table_Mulu(pc),a3
	move.w #SCREEN_WIDTH-1,d6
loop_draw_right_line
	movem.w (a2)+,d0/d1			clip le haut
	tst.w d0
	bge.s .ok1
	tst.w d1
	blt no_right_line_this_time
	moveq #0,d0
.ok1
	cmp.w #SCREEN_HEIGHT,d1			clip le bas
	blt.s .ok2
	cmp.w #SCREEN_HEIGHT,d0
	bge no_right_line
	move.w #SCREEN_HEIGHT-1,d1
.ok2
	sub.w d0,d1				hauteur en ligne
	lsl.w #6,d1
	addq.w #1,d1

	add.w d0,d0
	move.w 0(a3,d0.w),d0
	lea (SCREEN_WIDTH/8)-2(a1,d0.w),a0

.wait
	btst #14,dmaconr(a6)
	bne.s .wait

	move.l a0,bltapt(a6)			routine sp�ciale de trac�
	move.l a0,bltcpt(a6)			de droite verticale
	move.l a0,bltdpt(a6)
	moveq #SCREEN_WIDTH/8-2,d0
	move.w d0,bltcmod(a6)
	move.w d0,bltdmod(a6)
	move.w #1,bltadat(a6)
	move.l #$34a0000,bltcon0(a6)
	move.w d1,bltsize(a6)	

no_right_line_this_time
	dbf d7,loop_draw_right_line
no_right_line
	rts



********************************************************************************
*************                                                       ************
*************                REMPLISSAGE DU CHESSFIELD		    ************
*************                                                       ************
********************************************************************************
Fill_ChessField
	btst #14,dmaconr(a6)
	bne.s Fill_ChessField

	clr.l bltamod(a6)
	move.l #$9f00012,bltcon0(a6)

	move.l log_screen(pc),a0
	tst.w What_Visible-data_base(a5)
	beq.s it_s_ChessField
	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT*2-2(a0),a0
	move.l a0,bltapt(a6)
	move.l a0,bltdpt(a6)
	move.w #(SCREEN_HEIGHT*2)<<6+(SCREEN_WIDTH/16),bltsize(a6)
	rts

it_s_ChessField
	lea (SCREEN_WIDTH/8)*SCREEN_HEIGHT-2(a0),a0
	move.l a0,bltapt(a6)
	move.l a0,bltdpt(a6)
	move.w #(SCREEN_HEIGHT)<<6+(SCREEN_WIDTH/16),bltsize(a6)
	rts

dots_3d_ChessField
	dc.w -1000,-800
	dc.w -600,-800
	dc.w -200,-800
	dc.w +200,-800
	dc.w +600,-800
	dc.w +1000,-800

	dc.w +1000,-400
	dc.w +1000,+000
	dc.w +1000,+400

	dc.w +1000,+800
	dc.w +600,+800
	dc.w +200,+800
	dc.w -200,+800
	dc.w -600,+800
	dc.w -1000,+800

	dc.w -1000,+400
	dc.w -1000,+000
	dc.w -1000,-400

dots_3d_Cuted
	dc.w -1000,-800
	dc.w +1000,-800
	dc.w +1000,-158
	dc.w -1000,-158
	dc.w -1000,+800
	dc.w +1000,+800

dots_2d
	dcb.w 18*2
nb_right
	dc.w 0
nb_right1
	dc.w 0
nb_right2
	dc.w 0
right_point1
	dcb.w 18,0
right_point2
	dcb.w 18,0

	section cop,data_c
coplist1
	dc.w bpl1ptH,0
	dc.w bpl1ptL,0
	dc.w bpl2ptH,0
	dc.w bpl2ptL,0
	dc.w ddfstrt,$0030
	dc.w ddfstop,$00d8
	dc.w diwstrt,$2571
	dc.w diwstop,$35d1
set_nb_bpl=*+2
	dc.w bplcon0,$1200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,0
	dc.w bpl2mod,0
	dc.w color00,$000
col1=*+2
	dc.w color01,$fff
col2=*+2
	dc.w color02,$000
	dc.w color03,$000
	dc.l $fffffffe

coplist2
	dc.w bpl1ptH,0
	dc.w bpl1ptL,0
	dc.w bpl2ptH,0
	dc.w bpl2ptL,0
	dc.w ddfstrt,$0030
	dc.w ddfstop,$00d8
	dc.w diwstrt,$2571
	dc.w diwstop,$35d1
	dc.w bplcon0,$1200
	dc.w bplcon1,$0000
	dc.w bplcon2,$0000
	dc.w bpl1mod,0
	dc.w bpl2mod,0
	dc.w color00,$000
	dc.w color01,$fff
	dc.w color02,$000
	dc.w color03,$000
	dc.l $fffffffe

