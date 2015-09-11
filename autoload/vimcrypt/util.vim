" - Utility functions ----------------------------------------------------------

" Set var to val if it does not already exist.
function! vimcrypt#util#initvar(var, val)
    if !exists(a:var)
        exec 'let '.a:var.' = a:val'
    endif
endfunction
