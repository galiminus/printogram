class Image < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_one_attached :document

  after_create :create_pwinty_image

  def create_pwinty_image
    response = Pwinty.create_image(order, {
      sku: product.sku,
      url: document.blob.service_url,
      copies: 1,
      sizing: "ShrinkToFit",
    })
    self.update(pwinty_reference: JSON.parse(response.body)["data"]["id"])
  end
end
