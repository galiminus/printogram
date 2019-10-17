class Telegram::OrderController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::Session
  before_action :set_customer

  def welcome
    response = t("welcome.message", { name: @customer.name || "there"})

    respond_with :message, text: response, parse_mode: "HTML"
  end

  def new_order!(data = nil, *)
    response = t("new_order.message")

    respond_with :message, text: response, parse_mode: "HTML"
  end

  def ask_country
    # respond_with :message, text: response, reply_markup: {
    #   keyboard: [ISO3166::Country.all.map(&:name)],
    #   resize_keyboard: false,
    #   one_time_keyboard: true,
    #   selective: false,
    # }
  end

  def message(message)
    if message["sticker"].present?
      profile_photo_file_path = self.bot.get_file(file_id: message["sticker"]["file_id"])["result"]["file_path"]

      image = Image.create!(
        order: @customer.draft_order,
      )
      image.document.attach({
        io: open("https://api.telegram.org/file/bot#{self.bot.token}/#{profile_photo_file_path}"),
        filename: "sticker-#{ message["sticker"]["file_id"]}.pdf"
      })

      response = t("new_sticker.saved")
      respond_with :message, text: response, parse_mode: "HTML"

    elsif message["text"].present?
      result = Geocoder.search(message["text"]).first
      if result.blank?
        respond_with :message, text: "404"
      else
        respond_with :message, text: result.data.to_json
      end
    elsif message["location"].present?
      result = Geocoder.search([message["location"]["latitude"], message["location"]["longitude"]]).first
      if result.blank?
        respond_with :message, text: "404"
      else
        respond_with :message, text: result.data.to_json
      end
    end
  end

  def start!(data = nil, *)
    if @customer.draft_order.blank?
      welcome
    elsif @customer.draft_order.present?
      if @customer.draft_order.country_code.blank?
        ask_country
      end
    end

    # respond_with :message, text: response, reply_markup: {
    #   keyboard: [t('welcome.keyboard.buttons')],
    #   resize_keyboard: true,
    #   one_time_keyboard: true,
    #   selective: false,
    # }


  end

  def set_customer
    @customer = Customer.create_from_telegram! from
  end
end
