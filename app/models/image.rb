class Image < ApplicationRecord
  belongs_to :order

  has_one_attached :document
end
