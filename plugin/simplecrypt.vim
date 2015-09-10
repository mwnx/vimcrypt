" Generic code refactored from Noah Spurrier <noah@noah.org>'s ssl.vim
"

" - Variables ------------------------------------------------------------------

" Number of times to ask for the password:
let g:simplecrypt_tries = 3
" Whether to make (ciphertext) backups before overwriting:
let g:simplecrypt_make_backups = 1
let g:simplecrypt_encrypters = ['simplecrypt#gpg_encrypt',
                               \'simplecrypt#ssl_encrypt']
let g:simplecrypt_decrypters = ['simplecrypt#gpg_decrypt',
                               \'simplecrypt#ssl_decrypt']

" - Generic functions ----------------------------------------------------------

" @what: 'encrypt' or 'decrypt'
function! simplecrypt#setup(what)
    if !exists('b:simplecrypt_'.a:what)
        exec 'let cmd = simplecrypt#command(g:simplecrypt_'.a:what.'ers)'
        if !empty(cmd)
            exec 'let b:simplecrypt_'.a:what.' = cmd'
        endif
    endif
endfunction

" @flist: List of detector functions (stored as strings). One such function
" takes no arguments and should return either a command to decrypt/encrypt the
" current file, or "" if it does not know the current file type.
function! simplecrypt#command(flist)
    for i in a:flist
        exec 'let r = '.i.'()'
        if !empty(r)
            return r
        endif
    endfor
    return ''
endfunction

" @flist: List of detector functions (stored as strings). One such function
" takes no arguments and should return either a command to decrypt/encrypt the
" current file, or "" if it does not know the current file type.
" @cryptcmd: The vim wrapper command used to decrypt or encrypt. Takes the
" generated shell command as argument.
" function! simplecrypt#detect_and_exec(flist, cryptcmd)
"     let cmd = simplecrypt#command(a:flist)
"     if cmd
"         exec 'call '.a:cryptcmd.'(cmd)'
"     else
"         return 1
"     endif
" endfunction

function! simplecrypt#pre()
    setlocal cmdheight=3
    setlocal viminfo=
    setlocal noswapfile
    "setlocal nobackup
    setlocal noundofile
    setlocal shell=/bin/sh
    setlocal bin
    " TODO?: mlockall
endfunction

function! simplecrypt#post()
    setlocal nobin
    setlocal cmdheight&
    setlocal shell&
endfunction

" @command: Decryption or encryption shell command.
" FIXME: Retrying a read does not work on an already loaded file. This is due to
" the fact that 'undo' will not set the buffer back to the file's original
" plaintext content in that situation...
function! simplecrypt#interactive(command)
    let errfile = tempname()
    for i in range(1, g:simplecrypt_tries)
        if i > 1 | echo 'TRY '.i.'/'.g:simplecrypt_tries | endif
        echom ''
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

function! simplecrypt#read_interactive(command)
    if simplecrypt#interactive(a:command)
        echo "COULD NOT DECRYPT USING COMMAND: " . a:command
        return 1
    endif
endfunction

function! simplecrypt#ReadPre()
    unlet! b:simplecrypt_decrypted

    call simplecrypt#setup('decrypt')
    if exists('b:simplecrypt_decrypt')
        call simplecrypt#pre()
    endif
endfunction

function! simplecrypt#ReadPost_(command)
    call simplecrypt#read_interactive(a:command)
    call simplecrypt#post()
    execute ":doautocmd BufReadPost ".expand("%:r")
    redraw!
endfunction

function! simplecrypt#ReadPost()
    " Prevent recursive calls of ReadPost.
    if exists('b:simplecrypt_decrypted') | return | endif
    let b:simplecrypt_decrypted = 1

    if exists('b:simplecrypt_decrypt')
        call simplecrypt#ReadPost_(b:simplecrypt_decrypt)
    endif
endfunction

" function! simplecrypt#read(command)
"     call simplecrypt#ReadPre()
"     if simplecrypt#read_interactive(a:command) == 0
"         call simplecrypt#ReadPost_(a:command)
"     endif
" endfunction

" function! simplecrypt#detect_and_read()
"     call simplecrypt#detect_and_exec('simplecrypt#read')
" endfunction

" - Encrypting -----------------------------------------------------------------

function! simplecrypt#write_interactive(command)
    if simplecrypt#interactive(a:command)
        echo "COULD NOT ENCRYPT USING COMMAND: " . a:command
        return 1
    endif
endfunction

function! simplecrypt#WritePre_(command)
    call simplecrypt#pre()
    if simplecrypt#write_interactive(a:command)
        call simplecrypt#post()
        throw 'Save aborted.'
    endif
endfunction

function! simplecrypt#pre_write_backup()
    " if g:openssl_backup
    "     silent! exec '!cp '.shellescape(expand('<afile>')).
    "                 \' '.shellescape(expand('<afile>').'~')
    " endif
endfunction

function! simplecrypt#WritePre()
    call simplecrypt#setup('encrypt')
    if exists('b:simplecrypt_encrypt')
        call simplecrypt#pre_write_backup()
        call simplecrypt#WritePre_(b:simplecrypt_encrypt)
    endif
endfunction

function! simplecrypt#WritePost()
    if exists('b:simplecrypt_encrypt')
        call simplecrypt#post()
        silent! undo
        redraw!
    endif
endfunction

" function simplecrypt#write(command)
"     call simplecrypt#WritePre_(a:command)
"     if simplecrypt#write_interactive(a:command) == 0
"         call simplecrypt#write_post()
"     endif
" endfunction

" function! simplecrypt#detect_and_write()
"     call simplecrypt#detect_and_exec('simplecrypt#write')
" endfunction

" - OpenSSL --------------------------------------------------------------------

let g:ssl_aes_cipher = 'aes-256-cbc'

function! simplecrypt#ssl_cipher()
    let cipher = expand('%:e')
    if cipher == 'aes'
        return g:ssl_aes_cipher
    elseif cipher == 'bfa'
        return 'bf -a'
    elseif cipher == 'bf' " TODO: cipher in [...]
        return cipher
    else
        return ''
    endif
endfunction

function! simplecrypt#ssl_decrypt()
    let cipher = simplecrypt#ssl_cipher()
    if !empty(cipher) | return 'openssl ' . cipher . ' -d -salt'
    else              | return ''
    endif
endfunction

function! simplecrypt#ssl_encrypt()
    let cipher = simplecrypt#ssl_cipher()
    if !empty(cipher) | return 'openssl ' . cipher . ' -e -salt'
    else              | return ''
    endif
endfunction

" Not really necessary; does the same as ':w'.
function SSLEncrypt()
    simplecrypt#write('simplecrypt#ssl_encrypt')
endfunction

" - GPG ------------------------------------------------------------------------

let g:gpg_encrypt_command =
    \'gpg --no-use-agent --cipher-algo AES256 --symmetric'
" overridden by b:gpg_encrypt_command

function! simplecrypt#current_is_gpg_file()
    let ext = expand('%:e')
    if ext == 'gpg' || ext == 'gnupg' || ext == 'pgp'
        return 1
    endif
    if !empty(expand('%'))
        silent! exec
            \'!file -b '.shellescape(expand('%')).
            \"| grep -i '\\<\\(gpg\\|gnupg\\|pgp\\)\\>.*\\<encrypted\\>'"
        if !v:shell_error | return 1 | endif
    endif
    return 0
endfunction

function! simplecrypt#gpg_decrypt()
    if simplecrypt#current_is_gpg_file()
        return 'gpg -d'
    else
        return ''
    endif
endfunction

function! simplecrypt#gpg_encrypt()
    if simplecrypt#current_is_gpg_file()
        if exists('b:gpg_encrypt_command')
            return b:gpg_encrypt_command
        elseif exists('g:gpg_encrypt_command')
            return g:gpg_encrypt_command
        endif
    endif
    return ''
endfunction

" Useful when dealing with a new GPG encrypted file to be which does not bear a
" 'gpg', 'gnupg', or 'pgp' extension. Without using this command ':w' would of
" course save the file as plaintext.
function GPGEncrypt()
    simplecrypt#write('simplecrypt#gpg_encrypt')
endfunction

" ------------------------------------------------------------------------------

autocmd BufReadPre,FileReadPre     * call simplecrypt#ReadPre()
autocmd BufReadPost,FileReadPost   * call simplecrypt#ReadPost()
autocmd BufWritePre,FileWritePre   * call simplecrypt#WritePre()
autocmd BufWritePost,FileWritePost * call simplecrypt#WritePost()

" autocmd BufReadPre,FileReadPre     *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call s:OpenSSLReadPre()
" autocmd BufReadPost,FileReadPost   *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call s:OpenSSLReadPost()
" autocmd BufWritePre,FileWritePre   *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call s:OpenSSLWritePre()
" autocmd BufWritePost,FileWritePost *.des3,*.des,*.bf,*.bfa,*.aes,*.idea,*.cast,*.rc2,*.rc4,*.rc5,*.desx call s:OpenSSLWritePost()

