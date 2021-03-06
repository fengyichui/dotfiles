" ============================================================================
" File:        terminal.vim
" Description: terminal shape
" Author:      liqiang
" Licence:     Vim licence
" Version:     1.0
" Note:
" ============================================================================

if has('gui_running')
    finish
endif

if exists('g:loaded_terminal') && g:loaded_terminal
    finish
endif
let g:loaded_terminal = 1


" Fixkey_setKey() and Fixkey_setNewKey() fork from: https://github.com/drmikehenry/vim-fixkey
function! Fixkey_setKey(key, keyCode)
    execute "set " . a:key . "=" . a:keyCode
endfunction
function! Fixkey_mapKey(key, value)
    execute "map  " . a:key . " " . a:value
    execute "map! " . a:key . " " . a:value
endfunction

" New keys are taken from <F22> through <F37> and <S-F22> through <S-F37>
" <F20>,<F21> used for focus
let g:Fixkey_spareKeysBegin = 22 " from F22
let g:Fixkey_numSpareKeys = (37 - g:Fixkey_spareKeysBegin) * 2
let g:Fixkey_spareKeysUsed = 0

" Allocate a new key, set it to use the passed-in keyCode, then map it to the passed-in key.
function! Fixkey_setNewKey(key, keyCode)
    if g:Fixkey_spareKeysUsed >= g:Fixkey_numSpareKeys
        echohl WarningMsg
        echomsg "Unable to map " . a:key . ": ran out of spare keys"
        echohl None
        return
    endif
    let fn = g:Fixkey_spareKeysUsed
    let half = g:Fixkey_numSpareKeys / 2
    let shift = ""
    if fn >= half
        let fn -= half
        let shift = "S-"
    endif
    let newKey = "<" . shift . "F" . (g:Fixkey_spareKeysBegin + fn) . ">"
    call Fixkey_setKey(newKey, a:keyCode)
    call Fixkey_mapKey(newKey, a:key)
    let g:Fixkey_spareKeysUsed += 1
endfunction

" key fix
function! s:key_fix()
    " Get the keycode
    "   :iunmap <c-v>
    "   <ctrl-v><something-key> (insert mode)
    "
    " Get terminfo:
    "   $ infocmp

    """""""
    " ALT "
    """""""
    " leaving out problematic characters: 'O', double quote, pipe and '['
    let ascii_nums = [33] + range(35, 61) + range(63, 78) + range(81, 90) + range(94, 123) + [125, 126]
    " FIXME: termux can't cover this when 'map <A-S-p>'
    if empty($ANDROID_DATA)
        let ascii_nums += [80] " P
    endif
    let printable_characters = map(ascii_nums, 'nr2char(v:val)')
    for char in printable_characters
        call Fixkey_setKey("<M-".char.">", "\e".char)
    endfor

    """"""""
    " CTRL "
    """"""""
    " for <ctrl-enter> in mintty
    call Fixkey_setNewKey("<C-CR>", "")
endfunction

" fix alt/ctrl key
call s:key_fix()

" xterm cursor
" 1 or 0 -> blinking block
" 3 -> blinking underscore
" 4 -> solid underscore
" 5 -> blinking vertical bar
" 6 -> solid vertical bar
let s:cursor_normal  = "\e[1 q" " blinking block
let s:cursor_insert  = "\e[5 q" " blinking vertical bar
let s:cursor_replace = "\e[3 q" " blinking underscore
let s:cursor_undercurl_s = "\e[4:3m" " curly underline start
let s:cursor_undercurl_e = "\e[4:0m" " curly underline end

" tmux and xterm check
if !exists('$TMUX')
"    if &term =~ 'xterm' " remove $TERM check for SSH
        let &t_ti = s:cursor_normal . &t_ti
        let &t_SI = s:cursor_insert . &t_SI
        let &t_SR = s:cursor_replace . &t_SR
        let &t_EI = s:cursor_normal . &t_EI
        let &t_te = &t_te
        let &t_Cs = s:cursor_undercurl_s . &t_Cs
        let &t_Ce = s:cursor_undercurl_e . &t_Ce
"    endif
    finish
endif

" tmux key fix
function! s:tmux_key_fix()
    if &term =~ 'tmux' " tmux-256color
        " F11
        call Fixkey_setNewKey("<C-F11>", "\e[23;5~")
        call Fixkey_setNewKey("<S-F11>", "\e[23;2~")
        call Fixkey_setNewKey("<M-F11>", "\e[23;3~")
        " F12
        call Fixkey_setNewKey("<C-F12>", "\e[24;5~")
        call Fixkey_setNewKey("<S-F12>", "\e[24;2~")
        call Fixkey_setNewKey("<M-F12>", "\e[24;3~")
        " ALT-cursor
        call Fixkey_setNewKey("<M-up>",    "\e[1;3A")
        call Fixkey_setNewKey("<M-down>",  "\e[1;3B")
        call Fixkey_setNewKey("<M-right>", "\e[1;3C")
        call Fixkey_setNewKey("<M-left>",  "\e[1;3D")
    else
        " ALT-[F1-F12] (RVCT, TMUX)
"       call Fixkey_setNewKey("<M-F1>",  "\e\e[11~")
"       call Fixkey_setNewKey("<M-F2>",  "\e\e[12~")
"       call Fixkey_setNewKey("<M-F3>",  "\e\e[13~")
"       call Fixkey_setNewKey("<M-F4>",  "\e\e[14~")
"       call Fixkey_setNewKey("<M-F5>",  "\e\e[15~")
"       call Fixkey_setNewKey("<M-F6>",  "\e\e[17~")
"       call Fixkey_setNewKey("<M-F7>",  "\e\e[18~")
"       call Fixkey_setNewKey("<M-F8>",  "\e\e[19~")
"       call Fixkey_setNewKey("<M-F9>",  "\e\e[20~")
"       call Fixkey_setNewKey("<M-F10>", "\e\e[21~")
        call Fixkey_setNewKey("<M-F11>", "\e\e[23~")
        call Fixkey_setNewKey("<M-F12>", "\e\e[24~")
    endif
endfunction

" fix key
call s:tmux_key_fix()

" Wrap for tmux
function! s:tmux_wrap(s) " {{{
    " To escape a sequence through tmux:
    "
    " * Wrap it in these sequences.
    " * Any <Esc> characters inside it must be doubled.
    let tmux_start = "\ePtmux;"
    let tmux_end   = "\e\\"

    return tmux_start . substitute(a:s, "\e", "\e\e", 'g') . tmux_end
endfunction " }}}

" Screen, Focus(TMUX: set -sg focus-events on)
let s:save_screen = "\e[?1049h"
let s:restore_screen = "\e[?1049l"
let s:enable_focus_reporting = "\e[?1004h"
let s:disable_focus_reporting = "\e[?1004l"

" Tmux cursor shape (tmux not support 'curly underline')
let s:tmux_cursor_normal  = s:tmux_wrap(s:cursor_normal)
let s:tmux_cursor_insert  = s:tmux_wrap(s:cursor_insert)
let s:tmux_cursor_replace = s:tmux_wrap(s:cursor_replace)
let s:tmux_cursor_t_ti = &t_ti
let s:tmux_cursor_t_te = &t_te

" autocmd
function s:do_autocmd(event)
    let cmd = getcmdline()
    let pos = getcmdpos()
    exec 'silent doautocmd ' . a:event . ' <nomodeline> %'
    call setcmdpos(pos)
    return cmd
endfunction

" This function copied and adapted from https://github.com/sjl/vitality.vim
" If you want to try to understand what is going on, look into comments from
" that plugin.
function! s:tmux_fix()
    " This escape sequence is escaped to get through Tmux without being "eaten"
    let escaped_enable_focus_reporting = s:tmux_wrap(s:enable_focus_reporting) . s:enable_focus_reporting

    " Vim termcap
    let &t_SI = s:tmux_cursor_insert . &t_SI
    let &t_SR = s:tmux_cursor_replace . &t_SR
    let &t_EI = s:tmux_cursor_normal . &t_EI
    let &t_ti = s:tmux_cursor_normal . escaped_enable_focus_reporting . s:save_screen . &t_ti
    let &t_te = s:disable_focus_reporting . s:restore_screen . &t_te

    " When Tmux 'focus-events' option is on, Tmux will send <Esc>[O when the
    " window loses focus and <Esc>[I when it gains focus.
    exec "set <F20>=\e[O"
    exec "set <F21>=\e[I"

    nnoremap <silent> <F20> :silent doautocmd <nomodeline> FocusLost %<CR>
    nnoremap <silent> <F21> :silent doautocmd <nomodeline> FocusGained %<CR>

    onoremap <silent> <F20> <Esc>:silent doautocmd <nomodeline> FocusLost %<CR>
    onoremap <silent> <F21> <Esc>:silent doautocmd <nomodeline> FocusGained %<CR>

    vnoremap <silent> <F20> <Esc>:silent doautocmd <nomodeline> FocusLost %<CR>gv
    vnoremap <silent> <F21> <Esc>:silent doautocmd <nomodeline> FocusGained %<CR>gv

    inoremap <silent> <F20> <C-\><C-O>:silent doautocmd <nomodeline> FocusLost %<CR>
    inoremap <silent> <F21> <C-\><C-O>:silent doautocmd <nomodeline> FocusGained %<CR>

    cnoremap <silent> <F20> <C-\>e<SID>do_autocmd('FocusLost')<CR>
    cnoremap <silent> <F21> <C-\>e<SID>do_autocmd('FocusGained')<CR>

    tnoremap <silent> <F20> <C-W>:silent doautocmd <nomodeline> FocusLost %<CR>
    tnoremap <silent> <F21> <C-W>:silent doautocmd <nomodeline> FocusGained %<CR>
endfunction

" FocusGaine
let s:tmux_is_running = 0
let s:tmux_updatetime_save = 4000
function! s:tmux_normal_cursor_restore()
    " restore updatetime
    let &updatetime=s:tmux_updatetime_save
    augroup tmux_terminal
        autocmd!
    augroup END

    " When gain focus, vim can't handle normal-mode cursor sharp
    if mode()=~'^n' || mode()=~'^c'
        " force cursor to normal mode
"        silent! execute '!echo -ne ' . shellescape(s:tmux_cursor_normal, 0)
        silent! normal! r
    endif
endfunction
function! s:tmux_focus_gained()
    if s:tmux_is_running
        " updatetime 100ms to trigger CursorHold
        let s:tmux_updatetime_save=&updatetime
        set updatetime=60
        augroup tmux_terminal
            autocmd CursorHold * call s:tmux_normal_cursor_restore()
        augroup END
    endif
    let s:tmux_is_running = 1
endfunction

" FocusLosted
function! s:tmux_focus_losted()
    " cursor to insert sharp
    silent! execute '!echo -ne ' . shellescape(s:tmux_cursor_insert, 0)
endfunction

" Fix tmux issue
call <SID>tmux_fix()

" When '&term' changes values for '<F20>', '<F21>', '&t_ti' and '&t_te' are
" reset. Below autocmd restores values for those options.
autocmd TermChanged * call <SID>tmux_fix()

" restore vim 'autoread' functionality
autocmd FocusGained * call s:tmux_focus_gained()
autocmd FocusLost   * call s:tmux_focus_losted()

" Disable Focus
function! TmuxFocusDisable()
    " Vim termcap
    let &t_ti = s:tmux_cursor_normal . s:save_screen . s:tmux_cursor_t_ti
    let &t_te = s:restore_screen . s:tmux_cursor_t_te
endfunction
if exists('g:tmux_focus_disable')
    call TmuxFocusDisable()
endif

