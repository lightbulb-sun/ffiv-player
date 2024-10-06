!TYPE_OF_SOUND = $001e00
!NEXT_SOUND_ID  = $001e01
!CURRENT_SOUND_ID = $001e05

!SOUND_TYPE_MUSIC = $01
!SOUND_TYPE_SFX = $02

!SELECTED_MUSIC_ID = $001f00
!SELECTED_SFX_ID = $001f01
!CURRENT_MARKER = $001f02
!LAST_BUTTON_PRESSES = $001f03
!TMP_BYTE = $001f05

!NEW_BUTTON_PRESSES = $00
!CURRENT_BUTTON_PRESSES = $00602

!MASK_BUTTON_RIGHT = $01
!MASK_BUTTON_LEFT = $02
!MASK_BUTTON_DOWN = $04
!MASK_BUTTON_UP = $08
!MASK_BUTTON_A = $80
!FUN_CHANGE_SOUND = $048004

!MIN_TRACK = $01
!MAX_TRACK = $37

!MIN_SFX = $01
!MAX_SFX = $7f

!BG1 = 1
!BG2 = 2
!BG3 = 4

!BG1_BASE_ADDR = $0000
!BG3_BASE_ADDR = $2000

!VRAM_SIZE = $800
!VRAM_WORD_ADDRESSING = $80
!VRAM_WORD_ADDRESS = $2800

!MENU_MUSIC_ROW = 15
!MENU_MUSIC_COL = 6
!VRAM_MUSIC = !MENU_MUSIC_ROW*$20+!VRAM_WORD_ADDRESS+!MENU_MUSIC_COL

!VRAM_MUSIC_ID = !VRAM_MUSIC+6

!MENU_SFX_ROW = 17
!MENU_SFX_COL = 6
!VRAM_SFX = !MENU_SFX_ROW*$20+!VRAM_WORD_ADDRESS+!MENU_SFX_COL

!VRAM_SFX_ID = !VRAM_SFX+6

!BG34NBA = $210c
!DMA_LINEAR = $00
!DMA_CONST = $08
!VMAIN = $2115
!VMADD = $2116
!VMDATAL = $2118
!VMDATAH = $2119
!DMAMODE = $4300
!DMAPPUREG = $4301
!DMALEN = $4305
!MDMAEN = $420b
!HDMAEN = $420c
!DMAADDR = $4302
!DMAADDRBANK = $4304

!TEXT_PALETTE = 7

!TILE_MARKER = $003f
!TILE_A      = $0042
!TILE_ZERO   = $0080
!TILE_EMPTY  = $008a


lorom

; don't play any music at startup
org $008603
        lda     #0

org $008646
        jsl     load_graphics

org $00861a
        ; enable BG1+BG3
        lda     #(!BG1|!BG3)

org $00867a
        jsl     check_for_new_button_presses

org $0090a9
        jsl     vblank

org $01df00
load_graphics:
        ; replace original instruction
        jsl     $15ca8b

        lda.b   #(!BG3_BASE_ADDR>>12)
        sta.w   !BG3_BASE_ADDR
        jsr     init_variables
        jsr     load_alphabet
        jsr     clear_bg3
        jsr     draw_menu
        rtl


init_variables:
        lda.b   #0
        sta.w   !CURRENT_MARKER
        sta.w   !LAST_BUTTON_PRESSES
        sta.w   !LAST_BUTTON_PRESSES+1
        lda.b   #!MIN_TRACK
        sta.w   !SELECTED_MUSIC_ID
        lda.b   #!MIN_SFX
        sta.w   !SELECTED_SFX_ID
        rts


load_alphabet:
        ; taken from $8463
        ldx     #$2000
        stx     $47
        ldx     #$1000
        stx     $45
        lda     #$0a
        sta     $3c
        ldx     #$f000
        stx     $3d
        jsl     $15ca8b
        rts


clear_bg3:
        ldx.w   #!TILE_EMPTY
        stx.w   !TMP_BYTE
        stz     !HDMAEN
        ldx.w   #!VRAM_WORD_ADDRESS
.copy_low_byte
        stz     !VMAIN
        stx.w   !VMADD
        ldy.w   #(!DMA_LINEAR|!DMA_CONST|((!VMDATAL&$ff)<<8))
        sty.w   !DMAMODE
        ldy.w   #!TMP_BYTE
        sty.w   !DMAADDR
        stz     !DMAADDRBANK
        ldy.w   #!VRAM_SIZE
        sty.w   !DMALEN
        lda     #1
        sta     !MDMAEN
.copy_high_byte
        lda     #$80
        sta     !VMAIN
        stx.w   !VMADD
        lda.b   #(!VMDATAH&$ff)
        sta.w   !DMAPPUREG
        ldy.w   #(!TMP_BYTE+1)
        sty.w   !DMAADDR
        ldy.w   #!VRAM_SIZE
        sty.w   !DMALEN
        lda     #1
        sta     !MDMAEN
        rts


draw_menu:
        lda.b   #$80
        sta.w   !VMAIN
.draw_music
        ldx.w   #!VRAM_MUSIC
        stx.w   !VMADD
        ldx.w   #(!TILE_A+'M'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!TILE_A+'U'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!TILE_A+'S'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!TILE_A+'I'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!TILE_A+'C'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
.draw_sfx
        ldx.w   #!VRAM_SFX
        stx.w   !VMADD
        ldx.w   #(!TILE_A+'S'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!TILE_A+'F'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!TILE_A+'X'-'A'|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        rts


check_for_new_button_presses:
.check_for_new_a_button_press
        lda     !NEW_BUTTON_PRESSES
        and     #!MASK_BUTTON_A
        beq     .check_for_new_down_button_press
        lda     !LAST_BUTTON_PRESSES
        and     #!MASK_BUTTON_A
        bne     .check_for_new_down_button_press
        jsr     handle_a_button_press
        bra     .the_end
.check_for_new_down_button_press
        lda     !NEW_BUTTON_PRESSES+1
        and     #!MASK_BUTTON_DOWN
        beq     .check_for_new_up_button_press
.marker_goes_down
        lda.w   !CURRENT_MARKER
        eor.b   #$01
        sta.w   !CURRENT_MARKER
        jsr     stop_all_sounds
        bra     .the_end
.check_for_new_up_button_press
        lda     !NEW_BUTTON_PRESSES+1
        and     #!MASK_BUTTON_UP
        beq     .check_for_new_right_button_press
.marker_goes_up
        lda.w   !CURRENT_MARKER
        eor.b   #$01
        sta.w   !CURRENT_MARKER
        jsr     stop_all_sounds
        bra     .the_end
.check_for_new_right_button_press
        lda     !NEW_BUTTON_PRESSES+1
        and     #!MASK_BUTTON_RIGHT
        beq     .check_for_new_left_button_press
        jsr     handle_right_press
        bra     .the_end
.check_for_new_left_button_press
        lda     !NEW_BUTTON_PRESSES+1
        and     #!MASK_BUTTON_LEFT
        beq     .the_end
        jsr     handle_left_press
.the_end
        ldx.w   !CURRENT_BUTTON_PRESSES
        stx.w   !LAST_BUTTON_PRESSES
        rtl


handle_a_button_press:
        lda.w   !CURRENT_MARKER
        beq     .change_music
.chane_sfx
        jmp     change_sfx
.change_music
        jmp     change_music


handle_right_press:
        lda.w   !CURRENT_MARKER
        beq     .next_music
.next_sfx
        jmp     select_next_sfx
.next_music
        jmp     select_next_music


handle_left_press:
        lda.w   !CURRENT_MARKER
        beq     .prev_music
.prev_sfx
        jmp     select_prev_sfx
.prev_music
        jmp     select_prev_music


select_prev_music:
        lda     !SELECTED_MUSIC_ID
        dec
.check_if_below_min
        cmp     #!MIN_TRACK
        bcs     .not_below_min
.below_min
        lda     #!MAX_TRACK
.not_below_min
        sta     !SELECTED_MUSIC_ID
        rts


select_next_music:
        lda     !SELECTED_MUSIC_ID
        inc
.check_if_above_max
        cmp     #!MAX_TRACK+1
        bcc     .not_above_max
.above_max
        lda     #!MIN_TRACK
.not_above_max
        sta     !SELECTED_MUSIC_ID
        rts


select_prev_sfx:
        lda     !SELECTED_SFX_ID
        dec
.check_if_below_min
        cmp     #!MIN_SFX
        bcs     .not_below_min
.below_min
        lda     #!MAX_SFX
.not_below_min
        sta     !SELECTED_SFX_ID
        rts


select_next_sfx:
        lda     !SELECTED_SFX_ID
        inc
.check_if_above_max
        cmp     #!MAX_SFX+1
        bcc     .not_above_max
.above_max
        lda     #!MIN_SFX
.not_above_max
        sta     !SELECTED_SFX_ID
        rts


stop_music:
        lda.b   #!SOUND_TYPE_MUSIC
        sta.w   !TYPE_OF_SOUND
        lda.b   #0
        sta.w   !NEXT_SOUND_ID
        jsl     !FUN_CHANGE_SOUND


stop_sfx:
        lda.b   #!SOUND_TYPE_SFX
        sta.w   !TYPE_OF_SOUND
        lda.b   #0
        sta.w   !NEXT_SOUND_ID
        jsl     !FUN_CHANGE_SOUND
        rts


stop_all_sounds:
        jsr     stop_music
        jsr     stop_sfx
        rts


change_music:
        lda.b   #!SOUND_TYPE_MUSIC
        sta.w   !TYPE_OF_SOUND
        lda.w   !SELECTED_MUSIC_ID
        sta.w   !NEXT_SOUND_ID
        jsl     !FUN_CHANGE_SOUND
        rts


change_sfx:
        lda.b   #!SOUND_TYPE_SFX
        sta.w   !TYPE_OF_SOUND
        lda.w   !SELECTED_SFX_ID
        sta.w   !NEXT_SOUND_ID
        lda.b   #$80
        sta.w   !NEXT_SOUND_ID+1
        jsl     !FUN_CHANGE_SOUND
        rts


vblank:
        ; replace original instruction
        jsl     $15cae2

        jsr     draw_marker
        jsr     draw_selected_music_id
        jsr     draw_selected_sfx_id
        rtl


draw_marker:
        lda.w   !CURRENT_MARKER
        beq     .marker_music
.marker_sfx
        ldx.w   #(!VRAM_MUSIC-2)
        stx.w   !VMADD
        ldx.w   #(!TILE_EMPTY|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!VRAM_SFX-2)
        stx.w   !VMADD
        ldx.w   #(!TILE_MARKER|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        rts
.marker_music
        ldx.w   #(!VRAM_MUSIC-2)
        stx.w   !VMADD
        ldx.w   #(!TILE_MARKER|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        ldx.w   #(!VRAM_SFX-2)
        stx.w   !VMADD
        ldx.w   #(!TILE_EMPTY|(!TEXT_PALETTE<<10))
        stx.w   !VMDATAL
        rts


draw_selected_music_id:
        lda.b   #$80
        sta.w   !VMAIN
        ldx.w   #!VRAM_MUSIC_ID
        stx.w   !VMADD
.draw_high_nibble
        lda.w   !SELECTED_MUSIC_ID
        lsr.b   #4
        jsr     nibble_to_tile
        stx.w   !VMDATAL
.draw_low_nibble
        lda.w   !SELECTED_MUSIC_ID
        and.b   #$0f
        jsr     nibble_to_tile
        stx.w   !VMDATAL
        rts


draw_selected_sfx_id:
        lda.b   #$80
        sta.w   !VMAIN
        ldx.w   #!VRAM_SFX_ID
        stx.w   !VMADD
.draw_high_nibble
        lda.w   !SELECTED_SFX_ID
        lsr.b   #4
        jsr     nibble_to_tile
        stx.w   !VMDATAL
.draw_low_nibble
        lda.w   !SELECTED_SFX_ID
        and.b   #$0f
        jsr     nibble_to_tile
        stx.w   !VMDATAL
        rts


nibble_to_tile:
        rep     #$20
        and.w   #$000f
        cmp.w   #10
        bcs     .digit
.letter
        clc
        adc.w   #!TILE_ZERO
        bra     .the_end
.digit
        clc
        adc.w   #(!TILE_A-10)
.the_end
        ora.w   #(!TEXT_PALETTE<<10)
        tax
        sep     #$20
        rts
