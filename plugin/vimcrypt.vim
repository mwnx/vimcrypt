" - Variables ------------------------------------------------------------------

if !exists('g:enable_vimcrypt')
    let g:enable_vimcrypt = 1
endif
" Number of times to ask for the password:
let g:vimcrypt_tries = 3
" Whether to warn when an encrypted file is going to backed up:
let g:vimcrypt_warn_about_backups = 1
let g:vimcrypt_encrypters = ['gpg#encrypt',
                            \'ssl#encrypt']
let g:vimcrypt_decrypters = ['gpg#decrypt',
                            \'ssl#decrypt']

" ------------------------------------------------------------------------------

command! -bar -nargs=0 VimcryptEnable
    \ let g:enable_vimcrypt = 1
    \|call s:VimcryptDefineAutocommands()

command! -bar -nargs=0 VimcryptDisable
    \ let g:enable_vimcrypt = 0
    \|call s:VimcryptDefineAutocommands()

function! s:VimcryptDefineAutocommands()
    augroup vimcrypt
        au!
        if g:enable_vimcrypt
            autocmd BufReadPre,FileReadPre     * call vimcrypt#ReadPre()
            autocmd BufReadPost,FileReadPost   * call vimcrypt#ReadPost()
            autocmd BufWritePre,FileWritePre   * call vimcrypt#WritePre()
            autocmd BufWritePost,FileWritePost * call vimcrypt#WritePost()
        endif
    augroup END
endfunction

call s:VimcryptDefineAutocommands()
