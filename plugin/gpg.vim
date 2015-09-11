" Useful when dealing with a new GPG-encrypted-file-to-be which does not bear a
" 'gpg', 'gnupg', or 'pgp' extension. Without using this command ':w' would of
" course save the file as plaintext.
function! GPGEncrypt()
    vimcrypt#write('gpg#encrypt')
endfunction
