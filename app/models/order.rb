class Order < ApplicationRecord
  belongs_to :customer

  has_many :images

  def reference
    Base64.encode64(
      Digest::SHA256.digest("#{id}#{customer.id}")
    ).upcase[0..6]
  end
end
