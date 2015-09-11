" Generic code refactored from Noah Spurrier <noah@noah.org>'s ssl.vim
"

" if !exists('g:vimcrypt_loaded')
"     let g:vimcrypt_loaded = 1
" else
"     finish
" endif

" - Utility functions ----------------------------------------------------------

" set var to val if it does not already exist
function vimcrypt#initvar(var, val)
    if !exists(a:var)
        exec 'let '.a:var.' = a:val'
    endif
endfunction

" - Generic functions ----------------------------------------------------------

" @what: 'encrypt' or 'decrypt'
function! vimcrypt#setup(what)
    if !exists('b:vimcrypt_'.a:what)
        exec 'let cmd = vimcrypt#command(g:vimcrypt_'.a:what.'ers)'
        if !empty(cmd)
            exec 'let b:vimcrypt_'.a:what.' = cmd'
        endif
    endif
endfunction

" @flist: List of detector functions (stored as strings). One such function
" takes no arguments and should return either a command to decrypt/encrypt the
" current file, or "" if it does not know the current file type.
function! vimcrypt#command(flist)
    for i in a:flist
        exec 'let r = '.i.'()'
        if !empty(r)
            return r
        endif
    endfor
    return ''
endfunction

function! vimcrypt#pre()
    setlocal cmdheight=3
    setlocal viminfo=
    setlocal noswapfile
    setlocal noundofile
    setlocal shell=/bin/sh
    setlocal bin
    " TODO?: mlockall
endfunction

function! vimcrypt#post()
    setlocal nobin
    setlocal cmdheight&
    setlocal shell&
endfunction

" @command: Decryption or encryption shell command.
" FIXME: Retrying a read does not work on an already loaded file. This is due to
" the fact that 'undo' will not set the buffer back to the file's original
" plaintext content in that situation...
function! vimcrypt#interactive(command)
    let errfile = tempname()
    echom 'VimCrypt: Using: '.a:command
    for i in range(1, g:vimcrypt_tries)
        if i > 1 | echo 'TRY '.i.'/'.g:vimcrypt_tries | endif
        echo ''
        silent! execute '%!'.a:command.' 2>'.shellescape(errfile)
        if v:shell_error
            silent! undo
            echom "ERROR:"
            echom join(readfile(errfile), "\n")
            echom ''
        else
            return 0
        endif
        if v:shell_error > 127 | break | endif
    endfor
    call input('')
    return 1
endfunction

" - Decrypting -----------------------------------------------------------------

function! vimcrypt#read_interactive(command)
    if vimcrypt#interactive(a:command)
        echo "COULD NOT DECRYPT USING COMMAND: " . a:command
        return 1
    endif
endfunction

function! vimcrypt#ReadPre()
    unlet! b:vimcrypt_decrypted

    call vimcrypt#setup('decrypt')
    if exists('b:vimcrypt_decrypt')
        call vimcrypt#pre()
    endif
endfunction

function! vimcrypt#ReadPost_(command)
    call vimcrypt#read_interactive(a:command)
    call vimcrypt#post()
    execute ":doautocmd BufReadPost ".expand("%:r")
    redraw!
endfunction

function! vimcrypt#ReadPost()
    " Prevent recursive calls of ReadPost.
    if exists('b:vimcrypt_decrypted') | return | endif
    let b:vimcrypt_decrypted = 1

    if exists('b:vimcrypt_decrypt')
        call vimcrypt#ReadPost_(b:vimcrypt_decrypt)
    endif
endfunction

" - Encrypting -----------------------------------------------------------------

function! vimcrypt#write_interactive(command)
    if vimcrypt#interactive(a:command)
        echo "COULD NOT ENCRYPT USING COMMAND: " . a:command
        return 1
    endif
endfunction

function! vimcrypt#WritePre_(command)
    call vimcrypt#pre()
    if vimcrypt#write_interactive(a:command)
        call vimcrypt#post()
        throw 'Save aborted.'
    endif
endfunction

function! vimcrypt#warn_about_backups()
    if g:vimcrypt_warn_about_backups && &backup
        " The password prompt apparently adds empty lines in vim, so we need
        " more lines:
        setlocal cmdheight=5
        echohl WarningMsg
        echo 'Warning: The &backup option is set; '.expand('<afile>').
            \' will be backed up (in ciphertext form) to '.&backupdir.'!'
        echohl None
    endif
endfunction

function! vimcrypt#WritePre()
    call vimcrypt#setup('encrypt')
    if exists('b:vimcrypt_encrypt')
        call vimcrypt#warn_about_backups()
        call vimcrypt#WritePre_(b:vimcrypt_encrypt)
    endif
endfunction

function! vimcrypt#WritePost()
    if exists('b:vimcrypt_encrypt')
        call vimcrypt#post()
        silent! undo
        redraw!
    endif
endfunction
