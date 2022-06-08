Copyright>        OpenRadioss
Copyright>        Copyright (C) 1986-2022 Altair Engineering Inc.
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
Chd|  HM_SELECT_OPTION_BY_NAME               source/devtools/hm_reader/hm_select_option_by_name.F
Chd|-- called by -----------
Chd|--      HSTP                          starter/com/hstp/hstp.F 
Chd|-- calls ---------------
Chd|        MESSAGE_MOD                   share/message_module/message_mod.F
Chd|        SUBMODEL_MOD                  share/modules1/submodel_mod.F 
Chd|====================================================================
      SUBROUTINE HM_SELECT_OPTION_BY_NAME(ENTITY_TYPE,NAME_PARAM,SUB_INDEX)
C-----------------------------------------------
C   ROUTINE DESCRIPTION :
C   ===================
C   SELECT OPTION BY NAME
C-----------------------------------------------
C   DUMMY ARGUMENTS DESCRIPTION:
C   =================== 
C
C     NAME               DESCRIPTION                         
C
C     ENTITY_TYPE        KEYWORD SELECT
C     NAME_PARAM         NAME OF THE OPTION TO SELECT
C     SUB_INDEX          SUBMODEL INDEX OF THE OPTION TO SELECT
C============================================================================
C   M o d u l e s
C-----------------------------------------------
      USE MESSAGE_MOD       
      USE SUBMODEL_MOD
C-----------------------------------------------
C   I m p l i c i t   T y p e s
C-----------------------------------------------
#include      "implicit_f.inc"
C-----------------------------------------------
C   C o m m o n   B l o c k s
C-----------------------------------------------
#include      "nchar_c.inc"
C-----------------------------------------------
C   D u m m y   A r g u m e n t s
C-----------------------------------------------
C INPUT ARGUMENTS
      CHARACTER*50,INTENT(IN)::ENTITY_TYPE,NAME_PARAM
      INTEGER,INTENT(IN)::SUB_INDEX
C-----------------------------------------------
C   A n a l y s e   M o d u l e
C-----------------------------------------------
C-----------------------------------------------
C   L o c a l   V a r i a b l e s
C-----------------------------------------------
C-----------------------------------------------
C   E x t e r n a l   F u n c t i o n s
C-----------------------------------------------
C=======================================================================
      CALL CPP_SELECT_OPTION_BY_NAME(ENTITY_TYPE(1:LEN_TRIM(ENTITY_TYPE)),LEN_TRIM(ENTITY_TYPE),
     .                                NAME_PARAM(1:LEN_TRIM(NAME_PARAM)),LEN_TRIM(NAME_PARAM),SUB_INDEX ) 
      RETURN
C
      END





