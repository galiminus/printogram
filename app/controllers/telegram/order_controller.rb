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

   # {
   #  "update_id":746792400,
   #  "message": {
   #    "message_id":77,
   #        "date":1571333366,
   #        "sticker":
   #        {"width":512,
   #          "height":512,
   #          "emoji":"🐕",
   #          "set_name":"AxiDumbdles",
   #          "is_animated":false,
   #          "thumb":{
   #            "file_id":"AAQBAAM-AANSTf4Hk6rpoOh0pKT9bO8vAAQBAAdtAANbGwACFgQ",
   #            "file_size":6664,
   #            "width":128,
   #            "height":128
   #          },
   #          "file_id":
   #          "CAADAQADPgADUk3-B5Oq6aDodKSkFgQ","file_size":36192}}}


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
