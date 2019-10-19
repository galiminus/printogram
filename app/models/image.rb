class Image < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_one_attached :document
end
