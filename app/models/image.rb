class Image < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_one_attached :document

  after_commit :create_pwinty_image, on: [:create]

  def create_pwinty_image
    ActiveStorage.variable_content_types = (ActiveStorage.variable_content_types + ["image/webp"]).uniq # pretty dirty, but well...

    response = Pwinty.create_image(order, {
      sku: product.sku,
      # url: document.variant(convert: :png).processed.service_url,
      # url: "https://s3-eu-west-1.amazonaws.com/commfeed.net/logo.png",
      url: document.service_url,
      copies: 1,
      sizing: "ShrinkToFit",
    })
    self.update(pwinty_reference: JSON.parse(response.body)["data"]["id"])
  end
end
