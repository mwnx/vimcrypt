" Generic code refactored from Noah Spurrier <noah@noah.org>'s ssl.vim
"

" - Variables ------------------------------------------------------------------

" Number of times to ask for the password:
let g:simplecrypt_tries = 3
" Whether to warn when an encrypted file is going to backed up:
let g:simplecrypt_warn_about_backups = 1
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

function! simplecrypt#warn_about_backups()
    if g:simplecrypt_warn_about_backups && &backup
        " The password prompt apparently adds empty lines in vim, so we need
        " more lines:
        setlocal cmdheight=5
        echohl WarningMsg
        echo 'Warning: The &backup option is set; '.expand('<afile>').
            \' will be backed up (in ciphertext form) to '.&backupdir.'!'
        echohl None
    endif
endfunction

function! simplecrypt#WritePre()
    call simplecrypt#setup('encrypt')
    if exists('b:simplecrypt_encrypt')
        call simplecrypt#warn_about_backups()
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

" Interpret 'aes' extension as:
let g:ssl_aes_cipher = 'aes-256-cbc'
" overridden by b:ssl_aes_cipher

" List stolen from the openssl help.
let g:ssl_ciphers = [
   \'aes-128-cbc',      'aes-128-ecb',      'aes-192-cbc',      'aes-192-ecb',
   \'aes-256-cbc',      'aes-256-ecb',      'base64',           'bf',
   \'bf-cbc',           'bf-cfb',           'bf-ecb',           'bf-ofb',
   \'camellia-128-cbc', 'camellia-128-ecb', 'camellia-192-cbc', 'camellia-192-ecb',
   \'camellia-256-cbc', 'camellia-256-ecb', 'cast',             'cast-cbc',
   \'cast5-cbc',        'cast5-cfb',        'cast5-ecb',        'cast5-ofb',
   \'des',              'des-cbc',          'des-cfb',          'des-ecb',
   \'des-ede',          'des-ede-cbc',      'des-ede-cfb',      'des-ede-ofb',
   \'des-ede3',         'des-ede3-cbc',     'des-ede3-cfb',     'des-ede3-ofb',
   \'des-ofb',          'des3',             'desx',             'rc2',
   \'rc2-40-cbc',       'rc2-64-cbc',       'rc2-cbc',          'rc2-cfb',
   \'rc2-ecb',          'rc2-ofb',          'rc4',              'rc4-40',
   \'seed',             'seed-cbc',         'seed-cfb',         'seed-ecb',
   \'seed-ofb']
" Extra handled keyword: aes (see g:ssl_aes_cipher)

function! simplecrypt#ssl_cipher(cipher)
    if match(a:cipher, '\v^aesa?$') == 0
        if exists('b:ssl_aes_cipher') | let cipher = b:ssl_aes_cipher
        else                          | let cipher = g:ssl_aes_cipher
        endif
        if a:cipher[-1:] == 'a' | return cipher.' -a'
        else                    | return cipher
        endif
    endif
    for i in g:ssl_ciphers
        if match(a:cipher, '\v^'.i.'a?$') == 0
            if match(a:cipher, '\v^'.i.'a$') == 0 | return a:cipher[:-2].' -a'
            else                                  | return a:cipher
            endif
        endif
    endfor
    return ''
endfunction

function! simplecrypt#current_ssl_cipher()
    return simplecrypt#ssl_cipher(expand('%:e'))
endfunction

function! simplecrypt#ssl_decrypt()
    let cipher = simplecrypt#current_ssl_cipher()
    if !empty(cipher) | return 'openssl ' . cipher . ' -d -salt'
    else              | return ''
    endif
endfunction

function! simplecrypt#ssl_encrypt()
    let cipher = simplecrypt#current_ssl_cipher()
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
