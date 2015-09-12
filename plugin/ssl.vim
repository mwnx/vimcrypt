" Not really necessary; does the same as ':w'.

function! s:SSLEncrypt()
    let l:cmd = ssl#encrypt()
    if !empty(l:cmd)
        vimcrypt#write(l:cmd)
    else
        echoerr "SSL: couldn't find an appropriate cipher for this file."
    endif
endfunction

command! -nargs=0 SSLEncrypt call s:SSLEncrypt()
