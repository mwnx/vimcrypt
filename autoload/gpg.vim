" - GPG ------------------------------------------------------------------------

call vimcrypt#util#initvar('g:gpg#encrypt_command',
    \'gpg --no-use-agent --cipher-algo AES256 --symmetric')
" overridden by b:gpg_encrypt_command

function! gpg#current_is_gpg_file()
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

function! gpg#decrypt()
    if gpg#current_is_gpg_file()
        return 'gpg -d'
    else
        return ''
    endif
endfunction

function! gpg#encrypt()
    if gpg#current_is_gpg_file()
        if exists('b:gpg#encrypt_command')
            return b:gpg#encrypt_command
        elseif exists('g:gpg#encrypt_command')
            return g:gpg#encrypt_command
        endif
    else
        return ''
    endif
endfunction
