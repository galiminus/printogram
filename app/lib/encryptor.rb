class Encryptor
  def self.encrypt(string)
    encryptor.encrypt_and_sign(string)
  end

  def self.decrypt(string)
    encryptor.decrypt_and_verify(string)
  end

  private

  def self.encryptor
    ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0, ActiveSupport::MessageEncryptor.key_len])
  end
end
