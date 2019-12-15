require 'openssl'

aes = OpenSSL::Cipher.new("AES-128-ECB")
aes.encrypt
# aes.padding = 0
aes.key = "YELLOW SUBMARINE"
print aes.update("abcdefghijklmnop")
