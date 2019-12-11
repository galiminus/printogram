class Waifu
  def self.get_upscaled(image)
    RestClient::Request.execute(method: :post, url: 'https://api.deepai.org/api/waifu2x', timeout: 600,
      headers: {'api-key' => 'bdd4da82-619f-4cd3-a2d1-2db46205a04e'},
      payload: {
        'image' => image.document.service_url
      }
    )
  end
end