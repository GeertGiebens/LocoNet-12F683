; Date: 27 mrt 2018
; File: LocoNet_12F683.asm 
; By: Geert Giebens
; PIC: 12F683


; DISCLAIMER: LocoNet is een Copyrighted product van Digitrax Inc. 
;             De software en hardware mag enkel gebruikt worden 
;             voor persoonlijk gebruik en op risico van de 
;             gebruiker zelf. De auteur kan geen garantie  
;             bieden op de correcte werking van deze software.

;             LocoNet is a Copyrighted product of Digitrax Inc.
;             The software and hardware may only be used
;             for personal use and at risk of the user himself.
;             The author can not guarantee provide the correct
;             operation of this software.


; pin  PIC 12F683                       <--> PICKIT3   pin
;----------------------------------------------------------
; pin8 GND                              <--> GND       pin3       
; pin7 GP0 = OUT1: DIR='0'OR'1'         <--> ICSPDATA  pin4
; pin6 GP1 = IN:   CIn-                 <--> ICSPCLOCK pin5
; pin5 GP2 = OUT:  COout              
; pin4 GP3 = IN:   Program new address  <--> Vpp       pin1
; pin3 GP4 = OUT2: DIR='0'          
; pin2 GP5 = OUT3: DIR='1'            
; pin1 +5V                              <--> +5V       pin2


;                  PIC12F683
;                  ----U----  
;           +5V --|1       8|-- GND
;         OUT3 O--|2       7|----O OUT1               LocoNet RJ12
;         OUT2 O--|3       6|----O-------+--|47k|------O pin3-4
;  +--O  O----+---|4       5|---|220k|---+         +---O pin2-5
;  |  \__/    |    ---------             |         |
;  |   BPA    -                          -        GND
;  |         |2|                        |1|
; GND        |2|                        |8| 
;            |k|                        |0|   
;             -                         |k|  
;             |                          -  
;            +5V                         | 
;                                       GND 
; 
; BPA: BRIDGE FOR PROGRAM NEW ADDRESS 

;*****************************************************************

;OPC_SW_REQ :OPCODE: REQ SWITCH function: <0xB0>,<SW1>,<SW2>,<CHK>
;
;<SW1> =<0,A6,A5,A4- A3,A2,A1,A0>
;<SW2> =<0,0,DIR,ON- A10,A9,A8,A7>
;             |  |
;             |  ON=1  for Output ON, ON=0 for output OFF
;            DIR=1 for Closed,/GREEN, DIR=0 for Thrown/RED

;DIR=1 AND ON=1 --> OUT1= GND 
;DIR=0 AND ON=1 --> OUT1= +5V
;!After the power is switched on, OUT1 will be the last stored state!

;DIR=1 AND ON=1 --> OUT2= GND (active)  if OUTPUT_OFF_260ms=1 then OUT2 --> +5V after 260ms
;DIR=1 AND ON=0 --> OUT2= +5V
;DIR=0 AND ON=1 --> OUT3= GND (active)  if OUTPUT_OFF_260ms=1 then OUT3 --> +5V after 260ms
;DIR=0 AND ON=0 --> OUT3= +5V

;If input BPA is closed then the received address will be stored in EEPROM

;Important to know! There is a choice between how outputs  OUT2 and OUT3 react. 
;Each output will be switched off by the corresponding LocoNet opcode (OPC_SW_REQ with 
;SW2:DIR=’1’or’0’ and ON=’0’). But there is a possibility that the device itself switches off 
;the output after a time = 260ms. You can set this option in the following way: 
;If you program a new address, the device will look at the last received opcode before you
;removing the programming bridge. If in this opcode SW2:ON='1' then the device itself will 
;switch off the output. This is for personal reasons, some of my devices do not send an 
;opcode where SW2:ON=’0’ (for example toggle switches). Actually, it is safer to use this 
;option, because if the opcode for switching off does not arrive, the output will not switch off!

;*****************************************************************

	LIST P=12F683
	#INCLUDE "P12F683.INC"
	ERRORLEVEL -302

 __CONFIG  _FCMEN_ON & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _IESO_OFF &  _CP_OFF & _BOD_ON &  _INTRC_OSC_NOCLKOUT

	#DEFINE CARRIER_DETECT   FLAG,0	 ;if '1' then CARRIER_DETECT =1200µs
	#DEFINE OUTPUT_OFF_260ms FLAG,1  ;if '1' then OUT2/OUT3 OFF after 260ms
	
	#DEFINE _60µs            .38
	#DEFINE _90µs            .58
	
	#DEFINE PROGRAM_ADDRESS  GPIO,GP3
	#DEFINE OUT2             GPIO,GP4
	#DEFINE OUT3             GPIO,GP5
	#DEFINE OUT1             GPIO,GP0
	
	#DEFINE OPC_SW_REQ       0xB0
	#DEFINE _DIR             .5
	#DEFINE _ON              .4
	
	cblock 0x20
OPCODE
SW1
SW2
CHK
SW1_EEPROM
SW2_EEPROM
COUNTER
FLAG
	endc

;********************************************************************

	ORG 0x2100	
	DE 0x00     ;first address after upload PIC µC (address=0)
	DE 0x00
	
	ORG    0x0000		
	GOTO MAIN


;********************************************************************
;******************* INTERRUPT SERVICE ROUTINE  *********************
;********************************************************************

	ORG    0x0004	
    
	BTFSC INTCON,T0IF  
	GOTO $+8
	BTFSS OUTPUT_OFF_260ms
	GOTO $+3
	BSF OUT2
	BSF OUT3
	BCF PIR1,TMR1IF
	BCF OUTPUT_OFF_260ms
	RETFIE      	
	BSF CARRIER_DETECT
	BCF INTCON,T0IF
	RETFIE

			
;********************************************************************
;******************* MACRO  *****************************************
;********************************************************************

RESET_CARRIER_DETECT  MACRO

	BSF INTCON,GIE
	MOVLW .106
	MOVWF TMR0
	BCF CARRIER_DETECT
	ENDM
		
;********************************************************************
		
WAIT_FOR_STARTBIT  MACRO

	BTFSC CMCON0,COUT
	GOTO $-1
	NOP
	ENDM
				
;********************************************************************

READ_BYTE  MACRO  _BYTE

	CLRF _BYTE
	READ_BIT _BYTE,0,_90µs
	READ_BIT _BYTE,1,_60µs
	READ_BIT _BYTE,2,_60µs
	READ_BIT _BYTE,3,_60µs
	READ_BIT _BYTE,4,_60µs
	READ_BIT _BYTE,5,_60µs
	READ_BIT _BYTE,6,_60µs
	READ_BIT _BYTE,7,_60µs
	
	MOVLW _60µs              ;read stopbit ='1' 
	MOVWF COUNTER 
	DECFSZ COUNTER,F 
	GOTO $-1			 
	BTFSS CMCON0,COUT	
	GOTO LOOP
	NOP
	ENDM

READ_BIT  MACRO  RB_BYTE,  RB_BIT,  RB_µs

	MOVLW RB_µs	
	MOVWF COUNTER
	DECFSZ COUNTER,F
	GOTO $-1		
	BTFSC CMCON0,COUT	
	BSF RB_BYTE,RB_BIT
	ENDM

;********************************************************************

TEST_OPCODE  MACRO  M_OPCODE
		
	MOVLW M_OPCODE
	XORWF OPCODE,W
	BTFSS STATUS,Z
	GOTO LOOP
	NOP
	ENDM
	
;********************************************************************
 
CHK_TEST  MACRO 

	COMF CHK,F
	MOVF CHK,W
	XORWF OPCODE,W
	XORWF SW1,W
	XORWF SW2,W
	BTFSS STATUS,Z
	GOTO LOOP
	NOP
	ENDM
	
;********************************************************************
	
TEST_ADDRESS MACRO

	MOVF SW1,W
	XORWF SW1_EEPROM,W
	BTFSS STATUS,Z
	GOTO LOOP
	MOVF SW2,W
	XORWF SW2_EEPROM,W
	ANDLW b'00001111'
	BTFSS STATUS,Z
	GOTO LOOP
	NOP
	ENDM

;********************************************************************
		
SAVE_IN_EEPROM  MACRO ADR
				
	BANKSEL EEDAT
	BTFSC EECON1,WR
    GOTO $-1
	MOVWF EEDAT
	MOVLW ADR
	MOVWF EEADR
	BSF EECON1,WREN 	
	BCF INTCON,GIE 		
	BTFSC INTCON,GIE 	
	GOTO $-2 
	MOVLW 0x55 		
	MOVWF EECON2 
	MOVLW 0xAA
	MOVWF EECON2 
	BSF EECON1,WR		
	BSF INTCON,GIE 		
	BANKSEL 0
	ENDM

UPDATE_EEPROM  MACRO 	

	MOVF SW1,W
	MOVWF SW1_EEPROM
	SAVE_IN_EEPROM 0
	
	MOVF SW2,W
	BTFSS PROGRAM_ADDRESS
	GOTO $+6
	BTFSC SW2_EEPROM,_ON
	GOTO $+3
	ANDLW b'11101111'
	GOTO $+2
	IORLW b'00010000'
	MOVWF SW2_EEPROM
    NOP
	SAVE_IN_EEPROM 1
	NOP
	ENDM

;********************************************************************

SET_OUTPUT1  MACRO
		
	BTFSS SW2,_DIR
	GOTO $+3
	BSF OUT1
	GOTO $+2
	BCF OUT1
	NOP
	ENDM

SET_OUTPUT2_3  MACRO
		
	BTFSC SW2,_ON
	GOTO $+4
	BSF OUT2
	BSF OUT3
	GOTO $+.9
	BTFSS SW2,_DIR
	GOTO $+3
	BCF OUT2
	GOTO $+2
	BCF OUT3
	CLRF TMR1H
	CLRF TMR1L
    BTFSS PROGRAM_ADDRESS
    GOTO $+3
    BTFSC SW2_EEPROM,_ON
	BSF OUTPUT_OFF_260ms
 
	NOP
	ENDM

	
;********************************************************************
;******************* INIT  ******************************************
;********************************************************************			
		
INIT
	BCF STATUS,IRP
	banksel OSCCON
	BSF OSCCON,4               ;8MHz internal clock
	BSF OSCCON,SCS
	BSF OPTION_REG,7
	CLRF FLAG

;INIT IN/OUTPUTS
	banksel 0
	CLRF GPIO 
	MOVLW 07h 
	MOVWF CMCON0 
	banksel ANSEL
	CLRF ANSEL                 ;No analogue inputs
	MOVLW b'00001010'	
	MOVWF TRISIO
		
;INIT Vref		
	banksel VRCON
	MOVLW b'10001110'          ;3,45V Uref Comparator
	MOVWF VRCON
		
;INIT Comparator
	banksel CMCON0
	MOVLW b'00010011'
	MOVWF CMCON0
		
;INIT T1 8µs for RELAIS RESET TIME; and T0 for CD time
	banksel T1CON
	MOVLW b'00110001'
	MOVWF T1CON

	banksel OPTION_REG
	MOVLW b'00000011'
	MOVWF OPTION_REG
	banksel 0

;INIT INTERRUPT 
	BSF INTCON,GIE
	BSF INTCON,T0IE
    BSF INTCON,PEIE
    banksel PIE1
	BSF PIE1,TMR1IE
    banksel 0

;INIT VARIABLE FROM EEPROM
	BANKSEL EEADR
	MOVLW .0
	MOVWF EEADR  
	BSF EECON1,RD  
	MOVF EEDAT,W  
	BANKSEL 0
	MOVWF SW1_EEPROM

	BANKSEL EEADR
	MOVLW .1
	MOVWF EEADR  
	BSF EECON1,RD  
	MOVF EEDAT,W  
	BANKSEL 0
	MOVWF SW2_EEPROM
	MOVWF SW2

;INIT OUTPUTS
	SET_OUTPUT1
	BSF OUT2
	BSF OUT3
	RETURN


;********************************************************************
;******************* MAIN  ******************************************
;********************************************************************

MAIN
	CALL INIT

LOOP
	RESET_CARRIER_DETECT
	WAIT_FOR_STARTBIT
	BTFSS CARRIER_DETECT               ;CARRIER_DETECT  > 1200µs ?
	GOTO LOOP
	BCF INTCON,GIE

	READ_BYTE OPCODE
	TEST_OPCODE OPC_SW_REQ

	WAIT_FOR_STARTBIT
	READ_BYTE SW1

	WAIT_FOR_STARTBIT
	READ_BYTE SW2

	WAIT_FOR_STARTBIT
	READ_BYTE CHK
	CHK_TEST
		
	BTFSS PROGRAM_ADDRESS      	
	GOTO NEXT
	TEST_ADDRESS					
NEXT
	UPDATE_EEPROM
	SET_OUTPUT1
	SET_OUTPUT2_3	
	GOTO LOOP
		
	END