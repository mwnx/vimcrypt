" - Variables ------------------------------------------------------------------

call vimcrypt#util#initvar('g:vimcrypt_enable', 1)
" Number of times to ask for the password:
call vimcrypt#util#initvar('g:vimcrypt_tries', 3)
" Whether to warn when an encrypted file is going to backed up:
call vimcrypt#util#initvar('g:vimcrypt_warn_about_backups', 1)
call vimcrypt#util#initvar('g:vimcrypt_encrypters', ['gpg#encrypt',
                                                    \'ssl#encrypt'])
call vimcrypt#util#initvar('g:vimcrypt_decrypters', ['gpg#decrypt',
                                                    \'ssl#decrypt'])

" ------------------------------------------------------------------------------

command! -bar -nargs=0 VimcryptEnable
    \ let g:vimcrypt_enable = 1
    \|call s:VimcryptDefineAutocommands()

command! -bar -nargs=0 VimcryptDisable
    \ let g:vimcrypt_enable = 0
    \|call s:VimcryptDefineAutocommands()

function! s:VimcryptDefineAutocommands()
    augroup vimcrypt
        au!
        if g:vimcrypt_enable
            autocmd BufReadPre,FileReadPre     * call vimcrypt#ReadPre()
            autocmd BufReadPost,FileReadPost   * call vimcrypt#ReadPost()
            autocmd BufWritePre,FileWritePre   * call vimcrypt#WritePre()
            autocmd BufWritePost,FileWritePost * call vimcrypt#WritePost()
        endif
    augroup END
endfunction

call s:VimcryptDefineAutocommands()
