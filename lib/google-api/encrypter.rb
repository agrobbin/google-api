module GoogleAPI
  class Encrypter

    class << self

      def encrypt!(value)
        Base64.strict_encode64(crypt(:encrypt, value))
      end

      def decrypt!(value)
        crypt(:decrypt, Base64.strict_decode64(value))
      end

      protected
        def crypt(method, value)
          cipher = OpenSSL::Cipher::AES256.new(:CBC)
          cipher.send(method)
          cipher.key = GoogleAPI.encryption_key
          result = cipher.update(value)
          result << cipher.final
        end

    end

  end
end
