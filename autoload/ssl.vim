" - OpenSSL --------------------------------------------------------------------

" Interpret 'aes' extension as:
call vimcrypt#util#initvar('g:ssl#aes_cipher', 'aes-256-cbc')
" overridden by b:ssl_aes_cipher

" List stolen from the openssl help.
call vimcrypt#util#initvar('g:ssl#ciphers', [
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
   \'seed-ofb'])
" Extra handled keyword: aes (see g:ssl_aes_cipher)

function! ssl#cipher(cipher)
    if match(a:cipher, '\v^aesa?$') == 0
        if exists('b:ssl_aes_cipher') | let cipher = b:ssl#aes_cipher
        else                          | let cipher = g:ssl#aes_cipher
        endif
        if a:cipher[-1:] == 'a' | return cipher.' -a'
        else                    | return cipher
        endif
    endif
    for i in g:ssl#ciphers
        if match(a:cipher, '\v^'.i.'a?$') == 0
            if match(a:cipher, '\v^'.i.'a$') == 0 | return a:cipher[:-2].' -a'
            else                                  | return a:cipher
            endif
        endif
    endfor
    return ''
endfunction

function! ssl#current_cipher()
    return ssl#cipher(expand('%:e'))
endfunction

function! ssl#decrypt()
    let cipher = ssl#current_cipher()
    if !empty(cipher) | return 'openssl ' . cipher . ' -d -salt'
    else              | return ''
    endif
endfunction

function! ssl#encrypt()
    let cipher = ssl#current_cipher()
    if !empty(cipher) | return 'openssl ' . cipher . ' -e -salt'
    else              | return ''
    endif
endfunction
