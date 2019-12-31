runtime! debian.vim

set updatetime=500  " milliseconds
set nomodifiable
" -------------------------------------------------------------------------
" 我写的自动刷新，对非tmux中的，vim开启后需要用户操作了，才能开始自动刷新

function! Timer()
    " set modifiable
    call feedkeys("f\e")
    " call feedkeys('\<CR>')
    checktime
    if getline(1) == "finished"
        call Quit()
    endif
endfunction

function! Enter()
    sleep 50m
    normal <CR>
endfunction


set autoread
autocmd VimEnter,BufEnter,BufRead * call Enter()
autocmd FocusLost,WinLeave,FocusGained * call Timer()
autocmd CursorHold,CursorHoldI * call Timer()
autocmd CursorMoved,CursorMovedI * call Timer()

" -------------------------------------------------------------------------
" if filereadable(expand("/mfs/haoyu/server_conf/ENV/serverENV/admin_tool/watchforchanges.vim"))
    " source /mfs/haoyu/server_conf/ENV/serverENV/admin_tool/watchforchanges.vim
" endif
" let autoreadargs={'autoread':1}
" execute WatchForChanges('*',autoreadargs)


" ctrl+c 退出
function! Quit()
    execute ':silent ! touch '.expand('%:p:h').'/quitvim'
    update!
    quit!
endfunction

nnoremap <C-C> :call Quit()<CR>
vnoremap <C-C> :call Quit()<CR>
inoremap <C-C> <C-O>:call Quit()<CR>


set nocompatible                         " 关闭 vi 兼容模式
let g:loaded_matchparen=1                " 关闭括号匹配高亮
" set noshowmatch

" disable 'Press Enter or type command to continue' at startup.
set shortmess=a
set cmdheight=2


" if has("syntax")
"  syntax off
" endif


" command! -nargs=1 Silent execute ':silent !'.<q-args> | execute ':redraw!'



" set nolazyredraw
" set ttymouse=xterm2
" nnoremap <esc>^[ <esc>^[
" set mouse=a
" map <ScrollWheelUp> <C-Y>
" map <ScrollWheelDown> <C-E>

" set bg=dark
" hi! EndOfBuffer ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
" highlight EndOfBuffer ctermfg=black ctermbg=black
" hi NonText guifg=bg
"
"






