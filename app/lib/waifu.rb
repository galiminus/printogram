class Waifu
  def self.get_upscaled(image_url)
    client = Aws::SQS::Client.new({
      access_key_id: Rails.application.credentials.arthropod[:access_key_id],
      secret_access_key: Rails.application.credentials.arthropod[:secret_access_key],
      region: Rails.application.credentials.arthropod[:region],
    })
    response = Arthropod::Client.push(queue_name: "waifu2x", client: client, body: {
      image_url: image_url,
    })
    response.body["url"]
  end
end
