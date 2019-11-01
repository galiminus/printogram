class Telegram::OrderController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::Session

  before_action :set_customer
  before_action :set_product

  CONTINUE_ORDER = "Continue order"
  START_NEW_ORDER = "Start a new order"

  CANCEL_CLEAR_ORDER = "Cancel"
  CONFIRM_CLEAR_ORDER = "Sure"

  DONE_EDIT = "Done"

  def welcome
    respond_with :message, text: render("welcome"), parse_mode: "HTML"
  end

  def message(message)
    if message["sticker"].present?
      respond_with :message, text: render("sticker_loading"), parse_mode: "HTML"

      profile_photo_file_path = self.bot.get_file(file_id: message["sticker"]["file_id"])["result"]["file_path"]
      sticker = open("https://api.telegram.org/file/bot#{self.bot.token}/#{profile_photo_file_path}")

      image = Image.create!(
        order: @customer.draft_order,
        product: @product,
        document: {
          io: sticker,
          filename: "sticker-#{ message["sticker"]["file_id"]}.webp"
        }
      )
      BuildCartJob.perform_now(@customer.draft_order)

      if @customer.draft_order.images.count > 1
        @customer.draft_order.cart.open do |cart|
          respond_with :photo, photo: cart, caption: render("sticker_added"), parse_mode: "HTML"
        end
      else
        respond_with :message, text: render("sticker_added"), parse_mode: "HTML"
      end
    end
  end

  def callback_query(data = nil)
    bot.delete_message chat_id: chat["id"], message_id: payload["message"]["message_id"]

    if data == "CONTINUE_ORDER" || data == "CANCEL_CLEAR_ORDER" || data == "DONE_EDIT"
      respond_with :message, text: render("clear_order_cancelled"), parse_mode: "HTML"
    elsif data == "START_NEW_ORDER"
      @customer.draft_order.destroy
      respond_with :message, text: render("new_order_started"), parse_mode: "HTML"
    elsif data == "CONFIRM_CLEAR_ORDER"
      @customer.draft_order.destroy
      respond_with :message, text: render("order_cleared"), parse_mode: "HTML"
    else data.match(/^DELETE_IMAGE_/)
      id, index = data.match(/^DELETE_IMAGE_([0-9]+)_([0-9]+)$/)[1..2]

      respond_with :message, text: render("deleting_sticker", index: index.to_i), parse_mode: "HTML"

      @customer.draft_order.images.find(id).destroy

      if @customer.draft_order.images.any?
        BuildCartJob.perform_now(@customer.draft_order)
        @customer.draft_order.cart.open do |cart|
          respond_with :photo, photo: cart, caption: render("sticker_deleted"), parse_mode: "HTML"
        end
      else
        respond_with :message, text: render("order_cleared"), parse_mode: "HTML"
      end
    end
  end

  def continue!(data = nil)
    respond_with :message, text: render("continue"), parse_mode: "HTML"

    @customer.draft_order.cart.open do |cart|
      respond_with :photo, photo: cart, caption: render("clear_order_cancelled"), parse_mode: "HTML"
    end
  end

  def clear!(data = nil)
    respond_with :message, text: render("clear_order_confirmation"), reply_markup: {
      inline_keyboard: [
        [
          { text: CONFIRM_CLEAR_ORDER, callback_data: "CONFIRM_CLEAR_ORDER" },
          { text: CANCEL_CLEAR_ORDER, callback_data: "CANCEL_CLEAR_ORDER" },
        ]
      ]
    }
  end

  def new!(data = nil)
    if @customer.draft_order.images.count > 0
      respond_with :message, text: render("new_order_confirmation"), reply_markup: {
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

  def edit!(data = nil)
    respond_with :message, text: render("edit"), reply_markup: {
      inline_keyboard: [
        @customer.draft_order.images.map.with_index do |image, index|
          { text: (index + 1).to_s, callback_data: "DELETE_IMAGE_#{image.id}_#{index}" }
        end + [{ text: DONE_EDIT, callback_data: "DONE_EDIT" }]
      ]
    }
  end

  def start!(data = nil, *)
    respond_with :message, text: render("welcome"), parse_mode: "HTML"
  end

  def checkout!(data = nil, *)
    respond_with :message, text: render("checkout"), parse_mode: "HTML"
  end

  protected

  def render(path, locals = {})
    ActionController::Base.new.render_to_string("telegram/order/#{path}", locals: { customer: @customer, product: @product }.merge(locals))
  end

  def set_product
    @product = Product.first
  end

  def set_customer
    @customer = Customer.create_from_telegram! from
  end
end
