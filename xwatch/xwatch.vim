runtime! debian.vim

" let skip_defaults_vim=1

set mouse=a

" set nocompatible   " 关闭 vi 兼容模式；不得解注释之，不然'set viminfo='失效
set viminfo=        " 不输出日志文件，一避免污染vim的日志，二避免找不到日志文件而报错

set fileformats=dos " 让^M不显示
set updatetime=500  " milliseconds
set nomodifiable    " 禁止修改

" 隐藏所有状态栏
set noshowmode
set noruler
set laststatus=0
set noshowcmd
" set shortmess=F     " or set it as FAI
set cmdheight=1

set noeb vb t_vb=                " 关闭鸣叫。Timer函数执行时会鸣叫。
let g:loaded_matchparen=1        " 关闭括号匹配高亮
" set noshowmatch


" 配置多语言环境
if has("multi_byte")
    " UTF-8 编码
    set encoding=utf-8
    set termencoding=utf-8
    set formatoptions+=mM
    " set fileencoding=utf-8
    scriptencoding utf-8
    set fencs=utf-8,gbk
    if v:lang =~? '^\(zh\)\|\(ja\)\|\(ko\)'
        set ambiwidth=double
    endif
    if has("win32")
        source $VIMRUNTIME/delmenu.vim
        source $VIMRUNTIME/menu.vim
        language messages zh_CN.utf-8
    endif
else
    echoerr "Sorry, this version of (g)vim was not compiled with +multi_byte"
endif



" disable 'Press Enter or type command to continue' at startup.
" set cmdheight=2
" -------------------------------------------------------------------------
" if filereadable(expand("/mfs/haoyu/server_conf/ENV/serverENV/admin_tool/watchforchanges.vim"))
    " source /mfs/haoyu/server_conf/ENV/serverENV/admin_tool/watchforchanges.vim
" endif
" let autoreadargs={'autoread':1}
" execute WatchForChanges('*',autoreadargs)

let g:watch_file=0

" ctrl+c 退出
function! Quit()
    if g:watch_file == 0
        execute ':silent ! touch '.expand('%:p:h').'/quitvim'
    endif
    " update!
    quit!
endfunction

nnoremap <C-C> :call Quit()<CR>
vnoremap <C-C> :call Quit()<CR>
inoremap <C-C> <C-O>:call Quit()<CR>


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






