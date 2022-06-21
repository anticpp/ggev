require "test/unit"
require "internal/cipher"

class TestSimple < Test::Unit::TestCase

  def test_simple()
    puts "test_simple"
  end

  def test_cipher_gcm()
    key = Random::new.bytes(GGEV::CipherGCM::KEY_SIZE)
    data = "helloworld"
    auth_data = {}

    encrypt_cipher = GGEV::CipherGCM::new(key)
  end

end
