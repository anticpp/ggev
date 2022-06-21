require "openssl"
require "json"

module GGEV
  class CipherGCM
    KEY_SIZE = 16
    NONCE_SIZE = 12
    TAG_SIZE = 16

    @key = ""

    def initialize(key)
      raise "key size must be #{self::KEY_SIZE}" unless key.bytesize==self::KEY_SIZE
      @key = key
    end

    # Input:
    #   data      - Arbitrary bytes
    #   auth_data - Dictonary object, to be marshaled as JSON string
    # Output: 
    #   encrypted_data - <iv:12><encrypted_data><auth_tag:16>
    def encrypt(data, auth_data) 
      cipher = OpenSSL::Cipher::AES::new(128, :GCM).encrypt
      cipher.key = @key
      iv = cipher.random_iv
      cipher.auth_data = JSON::generate(auth_data)
      encrypted_data = cipher.update(data) + cipher.final
      return iv + encrypted_data + cipher.auth_tag
    end

    # Input:
    #   data      - Encrypted data
    #   auth_data - Dictonary object, to be marshaled as JSON string
    # Output: 
    #   decrypted_data - Arbitrary bytes
    def decrypt(data, auth_data)
      if data.bytesize < (self::NONCE_SIZE + self::TAG_SIZE)
        raise "data size invalid"
      end
      
      iv = data.slice!(0, self::NONCE_SIZE)
      auth_tag = data.slice!(data.size-self::TAG_SIZE, self::TAG_SIZE)
      
      cipher = OpenSSL::Cipher::AES::new(128, :GCM).decrypt
      cipher.key = @key
      cipher.iv = iv
      cipher.auth_tag = auth_tag
      cipher.auth_data = JSON::generate(auth_data)
      decrypted_data = cipher.update(data) + cipher.final
      return decrypted_data
    end
  end
end
