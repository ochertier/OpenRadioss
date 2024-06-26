Copyright>        OpenRadioss
Copyright>        Copyright (C) 1986-2024 Altair Engineering Inc.
Copyright>
Copyright>        This program is free software: you can redistribute it and/or modify
Copyright>        it under the terms of the GNU Affero General Public License as published by
Copyright>        the Free Software Foundation, either version 3 of the License, or
Copyright>        (at your option) any later version.
Copyright>
Copyright>        This program is distributed in the hope that it will be useful,
Copyright>        but WITHOUT ANY WARRANTY; without even the implied warranty of
Copyright>        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Copyright>        GNU Affero General Public License for more details.
Copyright>
Copyright>        You should have received a copy of the GNU Affero General Public License
Copyright>        along with this program.  If not, see <https://www.gnu.org/licenses/>.
Copyright>
Copyright>
Copyright>        Commercial Alternative: Altair Radioss Software
Copyright>
Copyright>        As an alternative to this open-source version, Altair also offers Altair Radioss
Copyright>        software under a commercial license.  Contact Altair to discuss further if the
Copyright>        commercial version may interest you: https://www.altair.com/radioss/.
Chd|====================================================================
Chd|  GETPHASE                      source/initial_conditions/inivol/getphase.F
Chd|-- called by -----------
Chd|        INITIA                        source/elements/initia/initia.F
Chd|-- calls ---------------
Chd|        MEAN_NODE_NORM2               source/initial_conditions/inivol/mean_node_norm2.F
Chd|        NFACETTE                      source/initial_conditions/inivol/nfacette.F
Chd|        PHASE_DETECTION               source/initial_conditions/inivol/phase_detection.F
Chd|====================================================================
      SUBROUTINE GETPHASE(X         ,SURF_TYPE ,ITAGNSOL ,DIS       ,NSOLTOSF  ,
     .                    SURF_ELTYP,KNOD2SURF ,NNOD2SURF,INOD2SURF ,TAGN      ,
     .                    IDSURF    ,NSEG      ,BUFSF    ,NOD_NORMAL,SURF_NODES,
     .                    IAD_BUFR  ,IDC       ,NBCONTY  ,NSEG_SWIFT_SURF,SWIFTSURF,
     .                    SEGTOSURF ,IVOLSURF  ,NSURF_INVOL,ITAB,NSEG_USED,
     .                    LEADING_DIMENSION,NB_CELL_X,NB_CELL_Y,NB_CELL_Z,
     .                    IPARG,IXS,IXQ,IXTG,
     .                    CELL,CELL_POSITION,NODAL_PHASE,NB_BOX_LIMIT)
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   G l o b a l   P a r a m e t e r s
C-----------------------------------------------
#include      "mvsiz_p.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
! com01 : ngroup/n2d
#include "com01_c.inc" 
#include "com04_c.inc"
#include "param_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
      INTEGER IDC,NBCONTY,ITAGNSOL(*),NSOLTOSF(NBCONTY,*),
     .  KNOD2SURF(*),NNOD2SURF,TAGN(*),IDSURF,NSEG,
     .  INOD2SURF(NNOD2SURF,*),SURF_TYPE,SURF_ELTYP(NSEG),
     .  SURF_NODES(NSEG,4),IAD_BUFR,SWIFTSURF(NSURF),NSEG_SWIFT_SURF,
     .  SEGTOSURF(*),IVOLSURF(NSURF),NSURF_INVOL
      my_real
     . X(3,*),DIS(NSURF_INVOL,*),BUFSF(*),
     . NOD_NORMAL(3,NUMNOD)
      INTEGEr, INTENT(IN) :: ITAb(NUMNOD)
      INTEGER, INTENT(IN) :: NSEG_USED
      INTEGER, INTENT(IN) :: LEADING_DIMENSION
      INTEGER, INTENT(IN) :: NB_BOX_LIMIT
      INTEGER, INTENT(IN) :: NB_CELL_X,NB_CELL_Y,NB_CELL_Z
      INTEGER, DIMENSION(NPARG,NGROUP), INTENT(IN) ::  IPARG  ! group data
      INTEGER, DIMENSION(NIXS,NUMELS),INTENT(IN), TARGET :: IXS ! solid data
      INTEGER, DIMENSION(NIXQ,NUMELQ),INTENT(IN), TARGET :: IXQ ! quad data
      INTEGER, DIMENSION(NIXTG,NUMELTG),INTENT(IN), TARGET :: IXTG ! triangle data
      INTEGER, DIMENSION(NUMNOD), INTENT(INOUT) :: NODAL_PHASE ! phase of nodes (in / out / near the surface)
      INTEGER, DIMENSION(3,NUMNOD), INTENT(IN) :: CELL_POSITION ! position of node/cell
      INTEGER, DIMENSION(NB_CELL_X,NB_CELL_Y,NB_CELL_Z), INTENT(INOUT) :: CELL ! phase of the voxcell
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
      INTEGER I,J,K,N,INOD,OK,OK1,OK2,FIRST,LAST,
     . IPL,IXPL1,IXPL2,IXPL3,IXPL4,OK3,IAD0,IN(4),ITYP,JJ,
     . IPASSN(NUMNOD),p,r,p1,p2,dd1(4),dd2(4),
     . NULL_DIST,IX2,SIZE_X2

      my_real
     . NX,NY,NZ,XFAS(3,4),DIST,DIST_OLD,X0,Y0,Z0,DOT,NSIGN(3),
     . SUM,XP1,YP1,ZP1,XP2,YP2,ZP2,AA,BB,CC,
     . DIST_PL(3),VX_NOD_INOD,VY_NOD_INOD,VZ_NOD_INOD,XSIGN(3),
     . V1X,V1Y,V1Z,V2X,V2Y,V2Z,V3X,V3Y,V3Z,V12X,V12Y,V12Z,XN(3),
     . TMP(3),SKW(9),XG,YG,ZG,DGR,X_PRIME,Y_PRIME,Z_PRIME
      DATA dd1/4,1,2,3/,dd2/2,3,4,1/
      INTEGER , DIMENSION(:), ALLOCATABLE   :: ID_X2_TAGN,CLOSEST_NODE_ID
C-----------------------------------------------
       IF(SURF_TYPE == 200) GOTO 950   ! case of infinite plane
       IF(SURF_TYPE == 101) GOTO 951   ! case of ellipsoid
C
       IX2 = 0
       ALLOCATE( ID_X2_TAGN(NUMNOD) )
       ID_X2_TAGN = 0
!
!    SWIFTSURF ---> tag for each container surface, continuously the total nb of 
!                   segments. This is used by "SEGTOSURF" to identify for each counted
!                   surface segment whom surface belongs
!
        SWIFTSURF(IDSURF) = NSEG_SWIFT_SURF
!
        IPASSN(1:NUMNOD) = 0
        FIRST = 1
        LAST  = MIN(NSEG,MVSIZ)
 800  CONTINUE
      DO 10 J=FIRST,LAST
        ITYP  = SURF_ELTYP(J)
        IN(1) = SURF_NODES(J,1)
        IN(2) = SURF_NODES(J,2)
        IN(3) = SURF_NODES(J,3)
        IN(4) = SURF_NODES(J,4)
C
        XFAS(1,1) = X(1,IN(1))
        XFAS(2,1) = X(2,IN(1))
        XFAS(3,1) = X(3,IN(1))
        XFAS(1,2) = X(1,IN(2))
        XFAS(2,2) = X(2,IN(2))
        XFAS(3,2) = X(3,IN(2))
        XFAS(1,3) = X(1,IN(3))
        XFAS(2,3) = X(2,IN(3))
        XFAS(3,3) = X(3,IN(3))
        XFAS(1,4) = X(1,IN(4))
        XFAS(2,4) = X(2,IN(4))
        XFAS(3,4) = X(3,IN(4))
C
        CALL NFACETTE(XFAS,NX,NY,NZ)
C-----
C fill cutting surfaces from shell elements
C-----
        IF (TAGN(IN(1)) == 0) THEN
          TAGN(IN(1)) = 1
          IX2 = IX2 + 1
          ID_X2_TAGN(IX2) = IN(1)
        ENDIF
        IF (TAGN(IN(2)) == 0) THEN
          TAGN(IN(2)) = 1
          IX2 = IX2 + 1
          ID_X2_TAGN(IX2) = IN(2)
        ENDIF
        IF (TAGN(IN(3)) == 0) THEN
          TAGN(IN(3)) = 1
          IX2 = IX2 + 1
          ID_X2_TAGN(IX2) = IN(3)
        ENDIF
        IF(TAGN(IN(4)) == 0)THEN
          TAGN(IN(4)) = 1
          IX2 = IX2 + 1
          ID_X2_TAGN(IX2) = IN(4)
        ENDIF
C
C fill normals to cut surfaces
        IF (ITYP == 3) THEN
          DO K=1,4
            N = IN(K)
            KNOD2SURF(N) = KNOD2SURF(N) + 1
!!            INOD2SURF(KNOD2SURF(N),N) = J
            INOD2SURF(KNOD2SURF(N),N) = J + NSEG_SWIFT_SURF
            SEGTOSURF(J + NSEG_SWIFT_SURF) = IDSURF
          ENDDO
        ELSEIF (ITYP == 7) THEN
          DO K=1,3
            N = IN(K)
            KNOD2SURF(N) = KNOD2SURF(N) + 1
!!            INOD2SURF(KNOD2SURF(N),N) = J
            INOD2SURF(KNOD2SURF(N),N) = J + NSEG_SWIFT_SURF
            SEGTOSURF(J + NSEG_SWIFT_SURF) = IDSURF
          ENDDO
        ENDIF ! IF(ITYP == 3)
C
        CALL MEAN_NODE_NORM2(IN,XFAS,NOD_NORMAL,NX,NY,NZ)
C---
 10     CONTINUE
C---
        IF(LAST < NSEG)THEN
          FIRST = LAST + 1
          LAST  = MIN(LAST+MVSIZ,NSEG)
          GOTO 800
        END IF
C-----
        NSEG_SWIFT_SURF = NSEG_SWIFT_SURF + NSEG
C------------------------------------
C     mean normmal to nodes
C------------------------------------
        DO N=1,NUMNOD
          IF (TAGN(N) == 1 .AND. IPASSN(N) == 0) THEN
            AA=ONE/MAX(EM30,SQRT(NOD_NORMAL(1,N)*NOD_NORMAL(1,N)+
     .                          NOD_NORMAL(2,N)*NOD_NORMAL(2,N)+
     .                          NOD_NORMAL(3,N)*NOD_NORMAL(3,N)))
            NOD_NORMAL(1,N)=NOD_NORMAL(1,N)*AA
            NOD_NORMAL(2,N)=NOD_NORMAL(2,N)*AA
            NOD_NORMAL(3,N)=NOD_NORMAL(3,N)*AA
            IPASSN(N) = 1
          ENDIF
        ENDDO ! DO N=1,NUMNOD

        ! -------------------------------
        ! find the phase of the elements : based on the distance of each node to the surface
        ! to avoid to many computation, the space is divided in cells
        ! the phase of each cell without any nodes of the surface is found
        ! then the cell's phase is applyed to the nodes belonging to the cell 
        SIZE_X2 = IX2
        ALLOCATE( CLOSEST_NODE_ID(NUMNOD) )
        CLOSEST_NODE_ID(1:NUMNOD) = -1
        CALL PHASE_DETECTION(LEADING_DIMENSION,NB_CELL_X,NB_CELL_Y,NB_CELL_Z,NB_BOX_LIMIT,
     .                       IPARG,IXS,IXQ,IXTG,X,IDSURF,
     .                       CELL,CELL_POSITION,NODAL_PHASE,CLOSEST_NODE_ID,
     .                       NNOD2SURF,KNOD2SURF,INOD2SURF,
     .                       NOD_NORMAL,NSEG_USED,SEGTOSURF,NSEG,SURF_ELTYP,SURF_NODES,SWIFTSURF)
        ! -------------------------------
        ! save the phase & the closest node of the surface are saved in DIS & NSOLTOSF arrays
        DO N=1,NUMNOD
            DIST = ZERO
            IF(TAGN(N) == 0) THEN
                DIST = NODAL_PHASE(N)
                NSOLTOSF(IDC,N) = CLOSEST_NODE_ID(N)
            ENDIF
            DIS(IVOLSURF(IDSURF),N) = DIST
        ENDDO
        DEALLOCATE( CLOSEST_NODE_ID ) 
        ! -------------------------------

C---

 950    CONTINUE
C---
        IF(SURF_TYPE /= 200) GOTO 951
C---
        IAD0 = IAD_BUFR
        XP1 = BUFSF(IAD0+1)
        YP1 = BUFSF(IAD0+2)
        ZP1 = BUFSF(IAD0+3)
        XP2 = BUFSF(IAD0+4)
        YP2 = BUFSF(IAD0+5)
        ZP2 = BUFSF(IAD0+6)
        AA = XP2 - XP1
        BB = YP2 - YP1
        CC = ZP2 - ZP1        
        DO N=1,NUMNOD
          IF (ITAGNSOL(N) /= 1) CYCLE
          DIST = ZERO
          DIST = AA*(X(1,N)-XP1)+BB*(X(2,N)-YP1)+CC*(X(3,N)-ZP1)
          SUM = SQRT(AA*AA+BB*BB+CC*CC)
          SUM = ONE/MAX(EM30,SUM)
          DIST = DIST*SUM
          DIS(IVOLSURF(IDSURF),N) = DIST
        ENDDO 
C---
C---
 951    CONTINUE
C---
        IF(SURF_TYPE /= 101) GOTO 960
C---
        IAD0 = IAD_BUFR
        AA = BUFSF(IAD0+1)
        BB = BUFSF(IAD0+2)
        CC = BUFSF(IAD0+3)
        XG = BUFSF(IAD0+4)
        YG = BUFSF(IAD0+5)
        ZG = BUFSF(IAD0+6)
        SKW(1)=BUFSF(IAD0+7)
        SKW(2)=BUFSF(IAD0+8)
        SKW(3)=BUFSF(IAD0+9)
        SKW(4)=BUFSF(IAD0+10)
        SKW(5)=BUFSF(IAD0+11)
        SKW(6)=BUFSF(IAD0+12)
        SKW(7)=BUFSF(IAD0+13)
        SKW(8)=BUFSF(IAD0+14)
        SKW(9)=BUFSF(IAD0+15)                                                                              
        DGR=BUFSF(IAD0+36)  
        !XG = SKW(1)*XG + SKW(4)*YG + SKW(7)*ZG 
        !YG = SKW(2)*XG + SKW(5)*YG + SKW(8)*ZG
        !ZG = SKW(3)*XG + SKW(6)*YG + SKW(9)*ZG     
        DO N=1,NUMNOD
          IF (ITAGNSOL(N) /= 1) CYCLE
          DIST=ZERO
          !matrice de passage
          X_PRIME = SKW(1)*(X(1,N)-XG) + SKW(4)*(X(2,N)-YG) + SKW(7)*(X(3,N)-ZG)
          Y_PRIME = SKW(2)*(X(1,N)-XG) + SKW(5)*(X(2,N)-YG) + SKW(8)*(X(3,N)-ZG)
          Z_PRIME = SKW(3)*(X(1,N)-XG) + SKW(6)*(X(2,N)-YG) + SKW(9)*(X(3,N)-ZG)
          TMP(1)= ABS(X_PRIME)/AA
          TMP(2)= ABS(Y_PRIME)/BB
          TMP(3)= ABS(Z_PRIME)/CC          
          !X_PRIME = SKW(1)*X(1,N) + SKW(4)*X(2,N) + SKW(7)*X(3,N)
          !Y_PRIME = SKW(2)*X(1,N) + SKW(5)*X(2,N) + SKW(8)*X(3,N)
          !Z_PRIME = SKW(3)*X(1,N) + SKW(6)*X(2,N) + SKW(9)*X(3,N)
          !TMP(1)= ABS(X_PRIME-XG)/AA
          !TMP(2)= ABS(Y_PRIME-YG)/BB
          !TMP(3)= ABS(Z_PRIME-ZG)/CC
          IF(TMP(1)/=ZERO)TMP(1)= EXP(DGR*LOG(TMP(1)))
          IF(TMP(2)/=ZERO)TMP(2)= EXP(DGR*LOG(TMP(2)))
          IF(TMP(3)/=ZERO)TMP(3)= EXP(DGR*LOG(TMP(3)))
          DIST = (TMP(1)+TMP(2)+TMP(3))          
          DIS(IVOLSURF(IDSURF),N) = ONE-DIST
        ENDDO
C---
 960    CONTINUE
C---
      IF (ALLOCATED (ID_X2_TAGN) ) DEALLOCATE (ID_X2_TAGN)
C-----------------------------------------------
      RETURN
      END
