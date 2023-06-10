﻿INCLUDE Enemy.asm
IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------
; SPACE INVADERS VARIABLES
startMassege db 'welcome to SPACE INVADERS', 10, 13
			db 'to shoot press "SPACE"', 10, 13
             db 'to move down press "s"', 10, 13
             db 'to move up press "w"', 10, 13		
             db 'to move left press "a"', 10, 13	
             db 'to move right press "d"', 10, 13	
			 db 'IN THE GAME!  press esc to quit.', 10, 13
             db 'now, press any key to start the game', 10, 13, '$'	 
byeMassege db 'thanks for playing... good bye$'	  
gameOver db 'game over you lost',10,13
		db 'press space to play again', 10,13, '$'

; sound variables
frequency DW 1000   ; Frequency of the sound effect (adjust as needed)
duration DW 1000    ; Duration of the sound effect (adjust as needed)

; draw pixel
placeX dw ?
placeY dw ?
color dw ?


; spaceShip variabels
spaceShipx dw 150
spaceShipy dw 195
SpaceShipColor dw 0fh
screenColor dw 0

; spaceShip laser varibales
laserArray dw 8 dup(?);contains all 4 laser x y of the players ?,?,?,?,?,?.?
LaserX dw ?
LaserY dw ?
LaserColor dw 2
LaserCounter dw  0
pressedSpace dw 0



; enemy varibales
enemyX dw ?
enemyY dw ?
enemyColor dw 1
enemyCounter dw 0
enemyArray dw 12 dup(0);contains all 6 Enemies x y of the players ?,?,?,?,?,?,?,?,?,?,?,?


; time variables
Clock  equ es:6Ch 
rand dw ?
delayTimer dw 0;manage the delay for the enemy creation

isCollied db 0;has true if there is a collision mid game
deadHeartsCounter dw 0
DELETESHOT DB ?
; --------------------------



CODESEG 
;---------------------------
; PROCedures 

; delete spaceship's laser after collision
PROC DELETESPACESHIPLASER

	DEC [laserY]
	PUSH CX
	MOV CX, [LaserX]
	MOV DX, [LaserY]
	MOV AH,0DH ;puts in al the color of the current pixel
	INT 10H
	pop cx

	inc [laserY]

	cmp AL, 1;if al equals to enemy's color
	JE CHECKING
	
	DEC [laserY]
	DEC [laserY]
	PUSH CX
	MOV CX, [LaserX]
	MOV DX, [LaserY]
	MOV AH,0DH ;puts in al the color of the current pixel
	INT 10H
	pop cx

	inc [laserY]
	inc [laserY]

	cmp AL, 1;if al equals to enemy's color
	JE CHECKING

	MOV [DELETESHOT], 0
	JMP NONE

	CHECKING:
	MOV [DELETESHOT], AL


	NONE:

ret
ENDP DELETESPACESHIPLASER


; creates a boom sound effect
PROC BOOMEFFECT
push cx
push DX
PUSH ax
PUSH BX

    ; Set up the registers for sound generation
    MOV DX, 67h    ; Port address for the timer
    MOV AL, 182    ; Control word for the timer
    OUT DX, AL

    MOV DX, 66h    ; Port address for the speaker
    MOV AX, [frequency]
    OUT DX, AL

    MOV CX, [duration]  ; Set the duration of the sound effect

    ; Loop to generate the sound effect
    PLAY_SOUND:
        ; Delay to control the speed of the sound effect (adjust as needed)
        MOV BX, 30
        DELAY_LOOP:
            DEC BX
            JNZ DELAY_LOOP

        ; Toggle the speaker state (on/off)
        MOV DX, 61h  ; Port address for the speaker control
        IN AL, DX    ; Read the current state
        XOR AL, 3    ; Toggle the first two bits (speaker control bits)
        OUT DX, AL   ; Update the speaker control

    LOOP PLAY_SOUND   ; Repeat the loop to continue playing the sound effect
POP BX
POP ax
POP dx
POP CX	 
ret
ENDP BOOMEFFECT


PROC hearts
push cx
push DX
PUSH ax
PUSH BX
	MOV AH,09         ; FUNCTION 9
	MOV AL,03          ; HEART ASCII
	MOV BX,0004    ; PAGE 0, COLOR 4
	MOV CX,4H  
	INT 10H

	MOV AH,09         ; FUNCTION 9
	MOV AL,03          ; HEART ASCII
	MOV BX,0017    ; PAGE 0, COLOR 4
	MOV CX, [deadHeartsCounter]  
	INT 10H

	cmp [deadHeartsCounter], 4
	jne gameContinue

	mov ah, 0
	mov al, 13h
	int 10h

	mov dx, offset gameOver;prints game over if the game is over
	mov ah, 9h
	int 21h

	WAITtoKey:

	mov ah, 7h  ; ממתין ללחיצה על משהו
	int 21h

	cmp al, 32d;if pressed space then the game is starting over
	jne WAITtoKey

	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	mov  ax, 40h 
	mov  es, ax 
	mov  ax, [Clock] 
	FirstTick:  
	cmp  ax, [Clock] 
	je  FirstTick  

	; Wait for key press
	mov ah,1
	int 21h

	mov ah, 0
	mov al, 13h
	int 10h

	call ResetVariables
	mov ah, 0
	mov al, 13h
	int 10h;restart graphics mode

	gameContinue:

	cmp al, 1Bh;if pressed escape then finish the program
	jne continue

	mov ax, 4c00h;finish the program
	int 21h

	continue:;continue the game

POP BX
POP ax
POP dx
POP CX	
RET
endp hearts


PROC drawPixel
; צייר נקודה
push ax
push bx
push cx
push dx
     mov bh,0h 
     mov cx,[placeX]  
     mov dx,[placeY] 
     mov ax, [color] 
     mov ah,0ch
     int 10h
pop dx
pop cx
pop bx
pop ax
ret 
endp drawPixel


PROC drawHead
	push [spaceShipx]
	push [spaceShipy]
	push [SpaceShipColor]
	pop [color]
	pop [placeY]
	pop [placeX]
	call drawPixel
ret
endp drawHead


PROC clearHead
	push [spaceShipx]
	push [spaceShipy]
	push [screenColor]
	pop [color]
	pop [placeY]
	pop [placeX]
	call drawPixel
ret
endp clearHead


PROC drawEnemyHead
	push [enemyX]
	push [enemyY]
	push [enemyColor]
	pop [color]
	pop [placeY]
	pop [placeX]
	call drawPixel
ret
endp drawEnemyHead


PROC clearEnemyHead
	push [enemyX]
	push [enemyY]
	push [screenColor]
	pop [color]
	pop [placeY]
	pop [placeX]
	call drawPixel
ret
endp clearEnemyHead


PROC LaserHead
	push [LaserX]
	push [LaserY]
	push [LaserColor]
	pop [color]
	pop [placeY]
	pop [placeX]
	call drawPixel
ret
endp LaserHead


PROC clearLaserHead
	push [LaserX]
	push [LaserY]
	push [screenColor]
	pop [color]
	pop [placeY]
	pop [placeX]
	call drawPixel
ret
endp clearLaserHead


PROC Laser
push ax
push bx
push cx
push dx
	call LaserHead;draw spaceship laser on the screen
	dec [LaserY]
	call LaserHead
pop dx
pop cx
pop bx
pop ax
ret
endp Laser


PROC clearLaser
push ax
push bx
push cx
push dx
	call clearLaserHead ;remove spaceship laser from the screen
	inc [LaserY]
	call clearLaserHead
pop dx
pop cx
pop bx
pop ax
ret
endp clearLaser



PROC drawLine
push ax
push bx
push cx
push dx
	mov [SpaceShipColor], 7 ;set the spaceship color to gray
	mov cx,16
	line:
		;draw a line to the screen (spaceship)
		call drawHead
		inc [spaceShipx]
	loop line
pop dx
pop cx
pop bx
pop ax
ret
endp drawLine



PROC clearLine
push ax
push bx
push cx
push dx
	mov cx, 16
	line2:
		;delete a line to the screen (spaceship)
		dec [spaceShipx]
		call clearHead
	loop line2
pop dx
pop cx
pop bx
pop ax
ret
endp clearLine



;LASER SEG

PROC createShot
push ax
push bx
push cx
push dx
push si

	mov si, 0 ;set the first place in the laser array (laserArray[0])

	cmp [pressedSpace], 0 ;if the program is able to perform the shot then create the shot else jump to the end
	jne endCreateLaser

	cmp [LaserCounter], 4 ;if there is more than 4 laser mid game then jump to the end else create a shot
	jge endCreateLaser

	loopLaserArray: ;while loop until an empty space for the new shot in the laser array

	cmp [laserArray + si], ? ;if the slot is empty then create a new shot else jumpt to the next slot
	jne nextLaserPos

	inc [LaserCounter] ;increase shots counter

	; laser x, set the laser x as the current spot of the spaceship
	mov ax, [spaceShipx]
	sub ax, 8
	mov [laserArray + si], ax

	; laser y, set the laser y as the current spot of the spaceship
	mov ax, [spaceShipy]
	sub ax, 2
	add si, 2
	mov [laserArray + si], ax

	jmp endCreateLaser ;finish PROC

	nextLaserPos: ;go to the next slot in the array
	add si, 4
	loop loopLaserArray

	endCreateLaser:
pop si
pop dx
pop cx
pop bx
pop ax
ret
ENDP createShot


PROC drawShot 
push ax
push bx
push cx
push dx
push si
push [LaserX]
push [laserY]

	mov si, 0 ;set the first place in the laser array (laserArray[0])

	mov cx,4 ;run over the array for times as the maximum laser at the same time
	LOOPOVERLASERARRAY:

	cmp [laserArray+si], ? ;check if the current x slot in the laser array is empty if true continute else go the next slot
	je nextLaser


	; laser x, set the laser x as the current spot of the spaceship
	mov ax, [laserArray + si]
	mov [LaserX], ax

	; laser y, set the laser y as the current spot of the spaceship
	add si, 2
	mov bx, [laserArray + si]
	mov [LaserY], bx


	; move the current shot forward
	call clearLaser
	dec [LaserY]
	call Laser

	; sync laser object with the updated values
	dec [laserArray + si]

	CALL DELETESPACESHIPLASER ;returns if the current shot damaged an enemy

	CMP [DELETESHOT], 1 ;if the current shot damaged an enemy then delete the current laser from the array and the screen
	JE REMOVELASER


	cmp [laserArray + si], 0 ;if the laser is in the end of the screen delete the laser else keep drawing the current laser
	jg continueDraw


	REMOVELASER:
	call moveEnemy ;draw enemy
	mov [laserArray + si], ? ;set the current slot empty
	mov [laserArray + si-2], ? 
	call clearLaser ;delete the current laser
	dec [LaserCounter] ;decrease the laser counter by 1


	continueDraw:
	add si, 2;jump to the next slot in the laser array
	jmp endOfLoop

	nextLaser:
	add si,4;jump to the next slot in the laser array

	endOfLoop:
	loop LOOPOVERLASERARRAY

	endPROC:
pop [laserY]
pop [LaserX]
pop si
pop dx
pop cx
pop bx
pop ax
ret
endp drawShot




PROC spaceShip
push ax
push bx
push cx
push dx
	call hearts
	call moveEnemy
	; https://asmsource1.tripod.com/images/coloursmall.jpg
	call drawLine;draw spaceship
pop dx
pop cx
pop bx
pop ax
ret
endp spaceShip


PROC clearSpaceShip
push ax
push bx
push cx
push dx
	call clearLine;delete spaceship
pop dx
pop cx
pop bx
pop ax
ret
endp clearSpaceShip




PROC enemy
push ax
push bx
push cx
push dx
	mov cx,8
	newline:
		call drawEnemyHead
		inc [enemyX]
		loop newline
pop dx
pop cx
pop bx
pop ax
ret
endp enemy


PROC clearEnemy
push ax
push bx
push cx
push dx
	mov cx, 8
	clearLinenew:
		dec [enemyX]
		call clearEnemyHead
	loop clearLinenew
pop dx
pop cx
pop bx
pop ax
ret
endp clearEnemy




PROC createEnemy
push ax
push bx
push cx
push dx
push si
push [enemyX]
push [enemyY]

mov si, 0 ;set the first place in the enemy's array (enemyArray[0])

untilEmptySlot:
;if current slot is empty jump to create the enemy else jump to the next slot
cmp [enemyArray + si], 0
jz drawEnemyNow

cmp [enemyArray + si+2], 0
jz drawEnemyNow

add si, 4 ;jump to the next slot
jmp untilEmptySlot


drawEnemyNow:
push 200
call random;generate a random x for the enemy to spawn
mov ax, [rand];put the returned value from random to ax
add ax, 9
mov [enemyArray + si], ax ;set the value from rand to the current enemy's x
mov [enemyArray + si+2], 0 ;set the y value of the current enemy as 0
inc [enemyCounter] ;increase the enemy's counter by 1

;reset system clock
mov ah,2dh
mov cx,0000h
mov dx,0000h
int 21h

jmp doneCreate


doneCreate:

pop [enemyY]
pop [enemyX]
pop si
pop dx
pop cx
pop bx
pop ax
ret
endp createEnemy


PROC collision
push ax
push cx
push dx
push si
push [enemyY]
push [enemyX]

	
	inc [enemyY]
	MOV CX, 9;loop over the current enemy's x (every enemy has 8 pixel)
	coll:
	push cx

	MOV CX, [enemyX]
	MOV DX, [enemyY]
	MOV AH,0DH;gets x & y, returns the pixel's color
	INT 10H
	pop cx

	mov [isCollied], al
	CMP [isCollied], 2 ;check if the current y pixel is the same color as the spaceship laser (2,green), if true finish PROC else jump to the next enemy's x
	je finito

	dec [ENEMYx]
	loop coll

	finito:

pop [enemyX]
pop [enemyY]
pop SI
pop DX
pop cx
pop ax
ret
endp collision



PROC moveEnemy
push ax
push bx
push cx
push dx
push si
push [enemyX]
push [enemyY]
	inc [delayTimer]

	cmp [delayTimer], 100 ;call createEnemy every 100 times the function being called
	jl loopOverEnemyArray
	mov [delayTimer], 0
	call createEnemy
	

	loopOverEnemyArray:

	cmp [enemyCounter], 0 ;if there is no enemys on the screen finish PROC
	jle finish


	mov si, 0 ;set the first place in the enemy's array (enemyArray[0])

	mov cx, 6 ;the enemys array length
	enemydown:
		; loads the current enemy's x from the enemyArray to ax
		mov ax, [enemyArray + si]
		

		add si, 2;jump to the Y of the current enemy in the enemyArray
		; loads the current enemy's Y from the enemyArray to bx
		mov bx, [enemyArray + si]


		cmp [enemyArray + si-2], ? ;if current slot is empty jump to create the enemy else jump to the next slot
		je nextEnemySlot

		mov [enemyX], ax ;set the global variable "enemyX" as X of the current enemy
		mov [enemyY], bx ;set the global variable "enemyY" as Y of the current enemy

	;move the current enemy down the screen
		call clearEnemy 
		inc [enemyY]
		call enemy
		
		
		inc [enemyArray + si] ;sync the current enemy values in the enemyArray

		call collision
		cmp [isCollied], 2 ;check if the current enemy got shot
		je clearEnemyFromScreen

		cmp [enemyArray + si], 200 ;check if the current enemy is in the buttom of the screen
		jle nextEnemySlot
		inc [deadHeartsCounter]

		; kill enemy
		clearEnemyFromScreen:
		call BOOMEFFECT
		call clearEnemy ;delete the current enemy from the screen
		mov [enemyArray + si-2], ? ;set the current enemy slot to empty
		mov [enemyArray + si], ? ;set the current enemy slot to empty

		nextEnemySlot:
		add si, 2
		mov [isCollied], 0

	loop enemydown

	finish:

pop [enemyY]
pop [enemyX]
pop si
pop dx
pop cx
pop bx
pop ax
ret
endp moveEnemy




;MOVEMENT SEG

PROC leftx
	cmp [spaceShipx], 0;if spaceship is in the border wont let it move towards the border else the spaceship will be able to move toward the pressed key
	jle leftBorder

	dec [spaceShipx]
	leftBorder:
ret
endp leftx


PROC rightx
	cmp [spaceShipx], 300 ;if spaceship is in the border wont let it move towards the border else the spaceship will be able to move toward the pressed key
	jge rightButton

	inc [spaceShipx]	
	rightButton:
ret
endp rightx


PROC upy
	cmp [spaceShipy], 0;if spaceship is in the border wont let it move towards the border else the spaceship will be able to move toward the pressed key
	jle topBorder

	dec [spaceShipy]
	topBorder:
ret
endp upy


PROC downy
	cmp [spaceShipy], 195 ;if spaceship is in the border wont let it move towards the border else the spaceship will be able to move toward the pressed key
	jge buttonBorder

	inc [spaceShipy]
	buttonBorder:
ret
endp downy



;LOGIC SEG

PROC random pascal
ARG @@num: byte

	push ax

	; generate random number, cx number of times
	mov ax, [Clock] ; read timer counter
	mov ah, [byte cs:bx] ; read one byte from memory
	xor al, ah ; xor memory and counter
	xor al, ah ; xor memory and counter
	and al, [@@num] ; leave result between 0-200
	mov ah, 00000100b
	mov [rand], ax
	add [rand], 100
	pop ax
	
ret
endp random


PROC delay
push dx
push cx
push ax
push es

;      mov  ax, 40h 
;      mov  es, ax 
;      mov  ax, [Clock] 
; FirstTick:  
;      cmp  ax, [Clock] 
;      je  FirstTick  

	mov cx, 45000
	numDelay:
	loop numDelay
pop es
pop ax
pop cx
pop dx
ret
endp delay


PROC ResetVariables
PUSH ax
PUSH BX
PUSH CX
PUSH dx
PUSH SI


; draw pixel
mov [placeX], ?
mov [placeY], ?
mov [color], ?


; spaceShip variabels
mov [spaceShipx], 150
mov [spaceShipy], 195
mov [SpaceShipColor], 0fh
mov [screenColor], 0



; spaceShip laser varibales
mov si,0
mov cx, 4
resetLaser:
MOV [laserArray + SI], ?
MOV [laserArray + SI+2], ?
ADD SI,4
loop resetLaser



mov si,0
mov cx, 6
resetEnemys:
MOV [enemyArray + SI], 0
MOV [enemyArray + SI+2], 0
ADD SI,4
loop resetEnemys



mov[LaserX], 50
mov [LaserY], 50
mov [LaserColor], 2
mov [LaserCounter],  0
mov [pressedSpace], 0

; enemy varibales
mov [enemyX], 0
mov [enemyY], 0
mov [enemyColor], 1
mov [enemyCounter], 0

; time variables
mov [rand], ?
mov [isCollied], 0
mov [deadHeartsCounter], 0

; reset system clock
mov ah,2dh
mov cx,0000h
mov dx,0000h
int 21h

POP SI
POP dx
POP CX
POP BX
POP AX
ret
endp ResetVariables

;Game PROCedure which starts the game every time you call it
PROC GAME
	call spaceShip


whatDirection:
	 mov ah, 7h ;קולט למעלה/למטה/ימינה/שמאלה
     int 21h   ; הפעם ממתין לקלט ולא מתחיל לשחק
 	 ;אלא אם כבר נקלט משהו ולא נמחק - תבינו את זה בהמשך 
     mov ah, 0


	cmp al, 'd' ; ימינה
	jz right
	
	cmp al, 'a' ; שמאלה
	jz left 
	
	cmp al, 's' ;למטה 
	jz down
	
	cmp al, 'w' ;למעלה
	jz up

	cmp al, 32d
	mov [pressedSpace], 0
	jz shooter

	
	cmp al, 1Bh ; esc לצאת מהמשחק
	jz bye ; קופץ לסוף - צריך תחנת בניים..
	
	jmp whatDirection  ; if wrong input, jumps and waits for a leagal one.



shooter:
	call moveEnemy
	call createShot
	
	call drawShot ;draw spaceship laser
	call delay

	inc [pressedSpace]

	mov ah, 1h
	int 16h
	je shooter
	jmp whatDirection


left:
	call drawShot ;draw spaceship laser
	call clearSpaceShip
	call leftx
	call spaceShip
    call delay

	mov ah, 1h
	int 16h
	je left 
	jmp whatDirection


right:
	call drawShot ;draw spaceship laser
	call clearSpaceShip
	call rightx ;checks if the spaceship doesn't cross the border
	call spaceShip
    call delay

	mov ah, 1h
	int 16h
	je right
	jmp whatDirection


down:
	call drawShot;draw spaceship laser
	call clearSpaceShip
	call downy;checks if the spaceship doesn't cross the border
	call spaceShip

    call delay
	mov ah, 1h
	int 16h
	je down
	jmp whatDirection


up:
	call drawShot;draw spaceship laser
	call clearSpaceShip
	call upy;checks if the spaceship doesn't cross the border
	call spaceShip

    call delay
	mov ah, 1h
	int 16h
	je up 
	jmp whatDirection

	
bye: 
	 mov dx, offset byeMassege
	 mov ah, 9h
	 int 21h	
	 
; Return to text mode
	mov ah, 0
	mov al, 2
	int 10h
; --------------------------
exit:
	mov ax, 4c00h
	int 21h
ret
ENDP GAME
;---------------------------


start:
	mov ax, @data
	mov ds, ax
	; initialize
	mov ax, 40h
	mov es, ax
	; --------------------------
; Your code here
; מעביר למצב גרפי
	mov ah, 0
	mov al, 13h
	int 10h
	
;הדפסת הודעת פתיחה	 
	mov dx, offset StartMassege
	mov ah, 9h
	int 21h
	mov ah, 7h  ; ממתין ללחיצה על משהו
	int 21h
	 


; מעביר  שוב למצב גרפי כדי לנקות את המסך 
	mov ah, 0
	mov al, 13h
	int 10h

	call game

END start