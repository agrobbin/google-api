module GoogleAPI
  class Encrypter

    class << self

      def encrypt!(value)
        crypt(:encrypt, value)
      end

      def decrypt!(value)
        crypt(:decrypt, value)
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
