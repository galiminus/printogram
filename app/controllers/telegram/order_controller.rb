class Telegram::OrderController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::Session

  before_action :set_customer

  CONTINUE_ORDER = "Continue order"
  START_NEW_ORDER = "Start a new order"

  def welcome
    respond_with :message, text: render("welcome"), parse_mode: "HTML"
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
      sticker = open("https://api.telegram.org/file/bot#{self.bot.token}/#{profile_photo_file_path}")
      image.document.attach({
        io: sticker,
        filename: "sticker-#{ message["sticker"]["file_id"]}.webp"
      })
      respond_with :message, text: render("sticker_added"), parse_mode: "HTML"

    elsif message["text"].present?
      result = Geocoder.search(message["text"]).first
      if result.blank?
        respond_with :message, text: render("error"), parse_mode: "HTML"
      else
        respond_with :message, text: result.data.to_json
      end

    elsif message["location"].present?
      result = Geocoder.search([message["location"]["latitude"], message["location"]["longitude"]]).first
      if result.blank?
        respond_with :message, text: render("error")
      else
        respond_with :message, text: result.data.to_json
      end
    end
  end

  def callback_query(data = nil)
    if data == "CONTINUE_ORDER"

    elsif data == "START_NEW_ORDER"
      @customer.draft_order.destroy
      respond_with :message, text: render("new_order_started"), parse_mode: "HTML"
    end
  end

  def clear!(data = nil)
    @customer.draft_order.destroy
    respond_with :message, text: render("order_cleared"), parse_mode: "HTML"
  end

  def new!(data = nil)
    if @customer.draft_order.images.count > 0
      respond_with :message, text: render("clear_order_confirmation"), reply_markup: {
        inline_keyboard: [
          [
            { text: START_NEW_ORDER, callback_data: "START_NEW_ORDER" },
            { text: CONTINUE_ORDER, callback_data: "CONTINUE_ORDER" },
          ]
        ]
      }
    else
      respond_with :message, text: render("new_order_started")
    end
  end

  def cart!(data = nil)
    respond_with :message, text: "Computing...", parse_mode: "HTML"

    Montage.create_cart(@customer.draft_order) do |path|
      open(path) do |image|
        reply_with :photo, photo: image
      end
    end
  end

  def summary!(data = nil)

  end

  def checkout!(data = nil)
    if @customer.draft_order.address1.blank?

    else

    end
  end

  def start!(data = nil, *)
    respond_with :message, text: render("welcome"), parse_mode: "HTML"

    # if @customer.draft_order.blank?
    #   welcome
    # elsif @customer.draft_order.present?
    #   if @customer.draft_order.country_code.blank?
    #     ask_country
    #   end
    # end

    # respond_with :message, text: response, reply_markup: {
    #   keyboard: [t('welcome.keyboard.buttons')],
    #   resize_keyboard: true,
    #   one_time_keyboard: true,
    #   selective: false,
    # }


  end

  protected

  def render(path)
    ActionController::Base.new.render_to_string("telegram/order/#{path}", locals: { customer: @customer })
  end

  def set_customer
    @customer = Customer.create_from_telegram! from
  end
end
