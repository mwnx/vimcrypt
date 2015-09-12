VimCrypt
========
> A small framework for encryption and decryption in vim.

VimCrypt is a small framework for reading and writing encrypted files within
vim. It comes with built-in support for:

- GPG (`gpg` plugin)
- OpenSSL (`ssl` plugin)

and is easily extensible.

It is useful for encrypting password files and other sensitive information,
using either symmetric (e.g. `ssl` and `gpg`) or asymmetric (e.g. `gpg`)
cryptography.

When you open an encrypted file or save an encrypted file, vim will forward
its contents to the appropriate encryption program (e.g. `gpg`), which will
–in most cases– prompt you for a passphrase.

File type Detection
-------------------
Each crypto plugin defines its own file type detection function.

###OpenSSl
The `ssl` plugin detects encryption and which cipher to use based solely on
the filename's extension. Note that `openssl` does not encode cipher
information within its files. Therefore, the extension must match the cipher
exactly.

The supported ciphers are those returned by the `openssl help` command, with
`aes` being an alias for `aes-256-cbc`, and an extra `a` appended to the
cipher meaning to use `openssl`'s `-a` option to produce an ASCII armoured
file.

Examples:

| Filename         | Command                  |
| ---------------  | ------------------------ |
| `auth.aes`       | `openssl aes-256-cbc`    |
| `auth.aesa`      | `openssl aes-256-cbc -a` |
| `x.bash.bf-ofb`  | `openssl bf-ofb`         |
| `x.bash.bf-ofba` | `openssl bf-ofb -a`      |

This behaviour is compatible with Noah Spurrier <noah@noah.org>'s
**ssl.vim** plugin.

###GPG
The `gpg` plugin uses the filename extension and the output of the `file`
command to determine whether the file is a GPG encrypted file or not. Thus,
a GPG encrypted file does not have to bear any particular extension to be
detected as such by this plugin.

Still, the supported extensions are: `.gpg`, `.pgp`, and `.gnupg`.

Dependencies
------------
Whatever programs are needed to decrypt the current file (e.g. `gpg` or
`openssl`).

TODO
----
- Add a **safe** system to check the newly entered password against the old
  password. If they are the same, don't ask for confirmation.
- For GPG, add a system to automatically reuse settings for the current
  file (symmetric vs assymetric, cipher, recepients, ...).

License
-------
This software (this whole repository) is published under the MIT license.
See the LICENSE file for details.
