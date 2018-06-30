; LC3 Rogue
; Created By: Justin Meiners (2017)

;---------------------------
; Program Setup
;---------------------------

.ORIG x3000 ; OS is <3000

WELCOME
    LEA R0, WELCOME_MESSAGE
    PUTs    
    GETc
    BRnzp MAIN 

WELCOME_MESSAGE .STRINGZ "Welcome to LC3 Rogue.\nUse WSAD to move.\nPress any key..\n"

MAIN
    LD R6, STACK_POINTER
    JSR BUILD_MAZE 
LOOP
    LD R0, COMPLETED
    BRp WIN
    JSR DISPLAY_MAZE
    JSR KEYBOARD
    HALT
WIN 
    AND R0, R0, x0   
    ST R0, COMPLETED 
    LEA R0, WIN_MESSAGE 
    PUTs
    GETc
    LD R1, N_NEG
    ADD R1, R0, R1
    BRnp MAIN
    HALT
    ; Constants
    WIN_MESSAGE .STRINGZ "You survived!\nOn to another dungeon? (n)o or any key to continue.\n"
    N_NEG .FILL xFF92
    STACK_POINTER .FILL x4000
    TEST_CHAR .FILL x41
    ; Maze Size
    W .FILL x20
    H .FILL x10
    ; Player position
    PX .FILL x0
    PY .FILL x0
    ;Game state
    COMPLETED .FILL x0
    MAZE_POINTER .FILL x3500

;---------------------------
; Keyboard Input
;---------------------------

KEYBOARD
    LD  R1, PX
    LD  R2, PY
    GETC 
    LD  R3, W_NEG ; Check up
    ADD R3, R0, R3
    BRz UP
    LD  R3, S_NEG ; Check down
    ADD R3, R0, R3
    BRz DOWN 
    LD  R3, A_NEG ; check left
    ADD R3, R0, R3
    BRz LEFT
    LD  R3, D_NEG ; check right
    ADD R3, R0, R3
    BRz RIGHT
    BRnzp KEYBOARD
UP
    ADD R2, R2, #-1 
    BRnzp MOVE
DOWN
    ADD R2, R2, #1
    BRnzp MOVE
LEFT
    ADD R1, R1, #-1
    BRnzp MOVE
RIGHT
    ADD R1, R1, #1   
    BRnzp MOVE    

;---------------------------
; Movement
;---------------------------

MOVE
    ; wrap X and Y coordinates
    AND R1, R1, x001F ; x % 32
    AND R2, R2, x000F ; y % 16 
    STR R1, R6, #-1    ; save x on stack
    STR R2, R6, #-2    ; save y on stack 
    ADD R6, R6, #-2
    JSR GET_CELL_POINTER
    LDR R3, R3, #0 
    BRz MOVE_PLAYER
    LD  R4, DOOR_ID_NEG
    ADD R3, R3, R4
    BRz MARK_DONE
    JSR LOOP
MOVE_PLAYER
    ; empty the old player cell
    LD  R1, PX
    LD  R2, PY 
    JSR GET_CELL_POINTER
    AND R4, R4, #0
    STR R4, R3, #0
    LDR R2, R6, #0    ; load y from xtack
    LDR R1, R6, #1    ; load x from stack
    ADD R6, R6, #2
    JSR GET_CELL_POINTER
    AND R4, R4, #0
    ADD R4, R4, #2    ; Player ID is 2
    STR R4, R3, #0    ; write player ID to new cell
    ST  R1, PX        ; store result, in px, py
    ST  R2, PY
    JSR LOOP
MARK_DONE
    ; store 1 in the completed variable
    AND R4, R4, #0
    ADD R4, R4, #1
    ST  R4, COMPLETED
    JSR LOOP
    W_NEG .FILL xFF89
    A_NEG .FILL xFF9F
    S_NEG .FILL xFF8D
    D_NEG .FILL XFF9C
    DOOR_ID_NEG .FILL xFFFC

;---------------------------
; Display
;---------------------------

DISPLAY_MAZE
    ; store on stack
    STR R7, R6, #-1
    ADD R6, R6, #-1
    LD  R3, W
    LD  R4, H
    LD  R5, MAZE_POINTER
    LEA R0, CLEAR_STRING
    PUTs
DISPLAY_CELL
    LDR R1, R5, #0      ; cell type
    LEA R2, TILE_CHARS
    ADD R2, R2, R1      ; Find char for cell type
    LDR R0, R2, #0      ; prepare for print
    OUT
    ADD R5, R5, #1      ; increment address
    ADD R3, R3, #-1     ; counter 
    BRp DISPLAY_CELL
    LD  R0, NEW_LINE    ; new line for new row
    OUT
    LD  R3, W           ; reset x counter
    ADD R4, R4, #-1
    BRp DISPLAY_CELL
    LD  R0, NEW_LINE
    OUT
    ; load from stack
    LDR R7, R6, #0
    ADD R6, R6, #1
    RET

NEW_LINE        .FILL  	    x0A         ; new line
TILE_CHARS      .STRINGZ  " #@KD"      ;  Character set for objects  
CLEAR_STRING	.STRINGZ	"\e[2J\e[H\e[3J"


; get the address for a maze coordinate given X, Y
; R1 = x, R2 = y
; R3 =  maze pointer + x + y * w
GET_CELL_POINTER
    ; push on to stack
    STR R0, R6, #-1
    STR R4, R6, #-2
    STR R5, R6, #-3
    STR R7, R6, #-4
    ADD R6, R6, #-4

    LD R3, MAZE_POINTER
    ; add x to pointer
    ADD R3, R3, R1
    ; add y * width loop
    ADD R4, R2, #0  ; setup y multiply counter
    BRz #4 
    LD R5, W
    ADD R3, R3, R5  ; add Width
    ADD R4, R4, #-1
    BRp #-3 
    ; pop from stack
    LDR R7, R6, #0
    LDR R5, R6, #1
    LDR R4, R6, #2
    LDR R0, R6, #3
    ADD R6, R6, #4
    RET

;---------------------------
; Maze Generation
;---------------------------

BUILD_MAZE
    ; store on stack
    STR R7, R6, #-1
    ADD R6, R6, #-1 
    ; fill in maze with solid blocks 
    LD  R1, W
    LD  R2, H
    AND R3, R3, x0
    ADD R3, R3, #1 
    LD  R5, MAZE_POINTER
BUILD_CELL
    STR R3, R5, #0
    ADD R5, R5, #1  ; increment pointer
    ADD R1, R1, #-1
    BRp BUILD_CELL
    LD  R1, W        ; reset counter
    ADD R2, R2, #-1
    BRp BUILD_CELL
    ; place the player on the left side, x = 0, y= rand
    JSR RAND 
    LD  R1, H 
    JSR MODULO ; R0 = rand % H
    ADD R2, R0, #0
    AND R1, R1, x0 ; x = 0
    JSR GET_CELL_POINTER
    AND R4, R4, #0
    ADD R4, R4, #2
    STR R4, R3, #0
    ST  R1, PX
    ST  R2, PY
    ; - w
    LD R4, W
    ADD R4, R4, #-1
    NOT R4, R4 
    ADD R4, R4, #1  
BUILD_TUNNEL
    ; while (x < w)   
    ; add to x
    ADD R1, R1, #1
    ; mark block empty
    JSR GET_CELL_POINTER   
    AND R5, R5, x0
    STR R5, R3, #0
    ; save x
    STR R1, R6, #-1
    ADD R6, R6, #-1
    ; rand % 3 + -1
    JSR RAND
    AND R1, R1, x0
    ADD R1, R1, #3
    JSR MODULO
    ADD R0, R0, #-1
    ADD R2, R2, R0  ; add to y
    AND R2, R2, x000F ; y % 16 
    LDR R1, R6, #0  ; pop x from stack
    ADD R6, R6, #1 
    JSR GET_CELL_POINTER   
    STR R5, R3, #0
    ; 
    ADD R5, R1, R4
    BRn BUILD_TUNNEL
    ; place door
    ADD R5, R5, #4
    STR R5, R3, #0     
    ; pop from stack
    LDR R7, R6, #0
    ADD R6, R6, #1
    RET

;---------------------------
; Utilities
;---------------------------

; R0 = rand
RAND
    ; push onto stack
    STR R1, R6, #-1
    STR R2, R6, #-2
    STR R3, R6, #-3
    STR R4, R6, #-4
    STR R5, R6, #-5
    STR R7, R6, #-6
    ADD R6, R6, #-6
    ; seed = (a * seed + c) % m
    LD  R1, SEED_A
    LD  R2, SEED
    AND R0, R0, x0
RAND_MULTIPLY     ; a * seed
    ADD R0, R0, R2
    ADD R1, R1, #-1
    BRp RAND_MULTIPLY
    LD  R1, SEED_C
    ADD R0, R0, R1 ; + C
    LD  R1, SEED_M
    AND R0, R0, R1 ; % m
    ST  R0, SEED
    ; pop from stack
    LDR R7, R6, #0
    LDR R5, R6, #1
    LDR R4, R6, #2
    LDR R3, R6, #3
    LDR R2, R6, #4
    LDR R1, R6, #5
    ADD R6, R6, #6
    RET

SEED   .FILL xAC34 ; made up number 
SEED_A .FILL #15245 ; made up
SEED_C .FILL #131 ; smaller incrementer
SEED_M .FILL x7FFF ; masks to last bit (prevents negative)

; R0 = (R0 % R1)
MODULO
    ; push onto stack
    STR R2, R6, #-1
    STR R3, R6, #-2
    STR R4, R6, #-3
    STR R5, R6, #-4
    STR R7, R6, #-5
    ADD R6, R6, #-5
    ; R1 = -q
    NOT R1, R1  ; 2's complement of 
    ADD R1, R1, #1 
    BRz MODULO_DONE ; if q is 0
    ADD R2, R0, R1  ; look ahead if x - q < 0  
    BRn MODULO_DONE
MODULO_LOOP
    ADD R0, R0, R1 ; x -= q
    ADD R2, R0, R1 ; look ahead
    BRzp MODULO_LOOP 
MODULO_DONE 
    ; pop from stack
    LDR R7, R6, #0
    LDR R5, R6, #1
    LDR R4, R6, #2
    LDR R3, R6, #3
    LDR R2, R6, #4
    ADD R6, R6, #5
    RET

.END 
 
