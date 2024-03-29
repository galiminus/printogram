class StickerLimitReached < StandardError; end

class Telegram::OrderController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::Session

  before_action :set_customer
  before_action :set_product
  before_action :set_customer_chat_reference

  CONTINUE_ORDER = "Continue order"
  START_NEW_ORDER = "Start a new order"

  CANCEL_CLEAR_ORDER = "Cancel"
  CONFIRM_CLEAR_ORDER = "Sure"

  CONFIRM_DELETE_IMAGE = "Delete"
  CANCEL_DELETE_IMAGE = "Cancel"

  CONFIRM_REMOVE_COUPON = "Remove"
  CANCEL_REMOVE_COUPON = "Cancel"

  CANCEL_FINAL_PREVIEW = "« Back"
  CONFIRM_FINAL_PREVIEW = "Looks good!"

  DONE_EDIT = "« Back"

  TERMS_REFUSE = "« Cancel"
  TERMS_AGREE = "I agree"

  rescue_from Exception do |error|
    if Rails.env.development?
      raise error
    else
      ExceptionNotifier.notify_exception(error)
    end

    respond_with :message, text: render("error"), parse_mode: "HTML"
  end

  def welcome
    respond_with :message, text: render("welcome"), parse_mode: "HTML"
  end

  def message(message)
    if message["sticker"].present?
      if message["sticker"]["is_animated"]
        return respond_with :message, text: render("animated_sticker_error"), parse_mode: "HTML"
      end

      if @customer.draft_order.images.count >= Rails.configuration.max_image_count_per_order
        return respond_with :message, text: render("max_image_count_per_order_reached"), parse_mode: "HTML"
      end

      respond_with :message, text: render("sticker_loading"), parse_mode: "HTML"

      begin
        add_sticker(message["sticker"])
      rescue StickerLimitReached
        respond_with :message, text: render("sticker_limit_reached"), parse_mode: "HTML"
        return
      end

      if @customer.draft_order.images.count > 1
        Montage.create_cart(@customer.draft_order) do |path|
          respond_with :photo, photo: open(path), caption: render("sticker_added"), parse_mode: "HTML"
        end
      else
        respond_with :message, text: render("sticker_added"), parse_mode: "HTML"
      end

    elsif message["successful_payment"].present?
      @customer.ongoing_order.update({
        telegram_payment_charge_reference: message["successful_payment"]["telegram_payment_charge_id"],
        provider_payment_charge_reference: message["successful_payment"]["provider_payment_charge_id"],
      })
      respond_with :message, text: render("successful_payment"), parse_mode: "HTML"
      CreatePwintyOrderWorker.perform_in(30.seconds, @customer.ongoing_order.id)
      return

    elsif message["text"].present? && message["text"].match(/^https:\/\/t.me\/addstickers\/.+$/)
      set_name = message["text"].match(/^https:\/\/t.me\/addstickers\/(.+)$/)[1]
      response = self.bot.get_sticker_set(name: set_name)

      allowed_stickers = response["result"]["stickers"].select do |sticker_message|
        !sticker_message["is_animated"]
      end

      if allowed_stickers.empty?
        return respond_with :message, text: render("animated_sticker_error"), parse_mode: "HTML"
      end

      if (@customer.draft_order.images.count + allowed_stickers.count) > Rails.configuration.max_image_count_per_order
        return respond_with :message, text: render("max_image_count_per_order_reached"), parse_mode: "HTML"
      end

      respond_with :message, text: render("sticker_set_loading"), parse_mode: "HTML"

      message = nil
      message_time = nil
      sticker_limit_warned = false
      allowed_stickers.each.with_index do |sticker_message, index|
        begin
          add_sticker(sticker_message)
        rescue StickerLimitReached
          if sticker_limit_warned == false
            respond_with :message, text: render("sticker_limit_reached_in_stickerset"), parse_mode: "HTML"
          end
          sticker_limit_warned = true
        end
      end

      Montage.create_cart(@customer.draft_order) do |path|
        respond_with :photo, photo: open(path), caption: render("sticker_added"), parse_mode: "HTML"
      end

    elsif message["text"].present? && country = (ISO3166::Country.find_country_by_name(message["text"]) || ISO3166::Country[message["text"]])
      @customer.draft_order.update(country_code: country.gec)

      respond_with :message, text: render("shipping_options", shipping_options: @customer.draft_order.shipping_options, country: country), parse_mode: "HTML"

    elsif message["text"].present? && coupon = Coupon.find_by(code: message["text"].strip.upcase)
      if coupon.expired? || !coupon.is_in_use_limit? || !coupon.is_in_use_limit_by_customer?(@customer)
        respond_with :message, text: render("coupon_expired"), parse_mode: "HTML"
      else
        @customer.draft_order.update(coupon: coupon)

        respond_with :message, text: render("coupon_saved"), parse_mode: "HTML"
      end

    elsif message["text"].present? && message["text"].match(/^[0-9]+$/)
      index = message["text"].to_i
      image = @customer.draft_order.images.order(created_at: :asc).to_a[index - 1]

      if image.blank?
        return respond_with :message, text: render("error_sticker_not_found", { index: index }), parse_mode: "HTML"
      end

      respond_with :message, text: render("delete_sticker_confirmation", { index: index }), reply_markup: {
        inline_keyboard: [
          [
            { text: CONFIRM_DELETE_IMAGE, callback_data: "DELETE_IMAGE_#{image.id}_#{index}" },
            { text: CANCEL_DELETE_IMAGE, callback_data: "CANCEL_DELETE_IMAGE" },
          ]
        ]
      }

    else
      respond_with :message, text: render("no_match"), parse_mode: "HTML"
    end
  end

  def callback_query(data = nil, *)
    begin
      bot.delete_message chat_id: chat["id"], message_id: payload["message"]["message_id"]
    rescue => error
      ExceptionNotifier.notify_exception(error)
    end

    if data == "CONTINUE_ORDER" || data == "CANCEL_CLEAR_ORDER" || data == "DONE_EDIT" || data == "KEEP_COUPON"
      respond_with :message, text: render("clear_order_cancelled"), parse_mode: "HTML"

    elsif data == "START_NEW_ORDER"
      @customer.draft_order.destroy
      respond_with :message, text: render("new_order_started"), parse_mode: "HTML"

    elsif data == "REMOVE_COUPON"
      @customer.draft_order.update(coupon: nil)
      respond_with :message, text: render("coupon_removed"), parse_mode: "HTML"

    elsif data == "CONFIRM_CLEAR_ORDER"
      @customer.draft_order.destroy
      respond_with :message, text: render("order_cleared"), parse_mode: "HTML"

    elsif data == "TERMS_REFUSE"
      respond_with :message, text: render("welcome"), parse_mode: "HTML"

    elsif data == "TERMS_AGREE"
      respond_with :message, text: render("new_order_started"), parse_mode: "HTML"

    elsif data == "CHECKOUT"
      if ENV["ENABLE_ORDERS"] == 'true'
        respond_with(:invoice, {
          title: "Checkout",
          description: "Please enter your payment and shipping information. The process is fully handled by Telegram and your private payment information will never be shared with us.",
          provider_token: Rails.application.credentials.stripe[:telegram_token],
          currency: "USD",
          start_parameter: "checkout",
          prices: [{ label: "#{@customer.draft_order.images.count} stickers", amount: @customer.draft_order.price }],
          need_name: true,
          need_shipping_address: true,
          payload: JSON.dump({ order_id: @customer.draft_order.id }),
          is_flexible: true,
        })
      else
        respond_with :message, text: render("orders_disabled"), parse_mode: "HTML"
      end

    elsif data.match(/^SET_CART_PAGE_/)
      page = data.match(/^SET_CART_PAGE_([0-9]+)$/)[1]
      edit_cart_keyboard(page.to_i)

    elsif data.match(/^DELETE_IMAGE_/)
      id, index = data.match(/^DELETE_IMAGE_([0-9]+)_([0-9]+)$/)[1..2]

      respond_with :message, text: render("deleting_sticker", index: index.to_i), parse_mode: "HTML"

       @customer.draft_order.images.find(id).destroy

      if @customer.draft_order.images.any?
        Montage.create_cart(@customer.draft_order) do |path|
          respond_with :photo, photo: open(path), caption: render("sticker_deleted"), parse_mode: "HTML"
        end
      else
        respond_with :message, text: render("order_cleared"), parse_mode: "HTML"
      end
    end
  end

  def continue!(data = nil, *)
    if @customer.draft_order.images.empty?
      respond_with :message, text: render("empty_order_error"), parse_mode: "HTML"
    else
      respond_with :message, text: render("continue"), parse_mode: "HTML"

      Montage.create_cart(@customer.draft_order) do |path|
        respond_with :photo, photo: open(path), caption: render("clear_order_cancelled"), parse_mode: "HTML"
      end
    end
  end

  def clear!(data = nil, *)
    respond_with :message, text: render("clear_order_confirmation"), reply_markup: {
      inline_keyboard: [
        [
          { text: CONFIRM_CLEAR_ORDER, callback_data: "CONFIRM_CLEAR_ORDER" },
          { text: CANCEL_CLEAR_ORDER, callback_data: "CANCEL_CLEAR_ORDER" },
        ]
      ]
    }
  end

  def new!(data = nil, *)
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
      respond_with :message, text: render("new_order_terms"), parse_mode: "HTML", reply_markup: {
        inline_keyboard: [
          [
            { text: TERMS_REFUSE, callback_data: "TERMS_REFUSE" },
            { text: TERMS_AGREE, callback_data: "TERMS_AGREE" },
          ]
        ]
      }
    end
  end

  def edit!(data = nil, *)
    edit_cart_keyboard(1)
  end

  def start!(data = nil, *)
    respond_with :message, text: render("welcome"), parse_mode: "HTML"
  end

  def terms!(data = nil, *)
    respond_with :message, text: render("terms_and_conditions"), parse_mode: "HTML"
  end

  def history!(data = nil, *)
    respond_with :message, text: render("history", orders: @customer.orders.where.not(state: "draft").order(:created_at)), parse_mode: "HTML"
  end

  def shipping!(data = nil, *)
    respond_with :message, text: render("shipping"), parse_mode: "HTML"
  end

  def more!(data = nil, *)
    respond_with :message, text: render("more"), parse_mode: "HTML"
  end

  def data!(data = nil, *)
    @customer.generate_data! do |path|
      respond_with :document, document: open(path)
    end
  end

  def faq!(data = nil, *)
    respond_with :message, text: render("faq"), parse_mode: "HTML"
  end

  def cart!(data = nil, *)
    respond_with :message, text: render("cart"), parse_mode: "HTML"
  end

  def order!(data = nil, *)
    order = @customer.orders.find_each.find { |o| o.reference == data }
    if order.blank?
      respond_with :message, text: render("no_order", { reference: data }), parse_mode: "HTML"
    else
      if order.preview.attached?
        respond_with :photo, photo: open(order.preview.service_url), caption: render("order", { order: order }), parse_mode: "HTML"
      else
        respond_with :message, text: render("order", { order: order }), parse_mode: "HTML"
      end
    end
  end

  def checkout!(data = nil, *)
    if @customer.draft_order.images.empty?
      respond_with :message, text: render("empty_order_error"), parse_mode: "HTML"
    elsif @customer.draft_order.price == 0
      respond_with :message, text: render("missing_paid_items_error"), parse_mode: "HTML"
    else
      respond_with :message, text: render("final_preview_loading"), parse_mode: "HTML"
      Montage.create_cart(@customer.draft_order, full_quality: true) do |path|
        respond_with :photo, photo: open(path), caption: render("final_preview_disclaimer"), parse_mode: "HTML", reply_markup: {
          inline_keyboard: [
            [
              { text: CANCEL_FINAL_PREVIEW, callback_data: "CONTINUE_ORDER" },
              { text: CONFIRM_FINAL_PREVIEW, callback_data: "CHECKOUT" },
            ]
          ]
        }
      end
    end
  end

  def coupon!(data = nil, *)
    if @customer.draft_order.coupon.present?
      respond_with :message, text: render("remove_coupon"), parse_mode: "HTML", reply_markup: {
        inline_keyboard: [
          [
            { text: CONFIRM_REMOVE_COUPON, callback_data: "REMOVE_COUPON" },
            { text: CANCEL_REMOVE_COUPON, callback_data: "KEEP_COUPON" },
          ]
        ]
      }
    else
      respond_with :message, text: render("coupon"), parse_mode: "HTML"
    end
  end

  def error!(data = nil, *)
    raise RuntimeError
  end

  def edit_cart_keyboard(page)
    page_size = 5
    before_page = { text: "«", callback_data: "SET_CART_PAGE_#{page - 1}" } if page > 1
    next_page = { text: "»", callback_data: "SET_CART_PAGE_#{page + 1}" } if page <= (@customer.draft_order.images.count - 1) / page_size

    respond_with :message, text: render("edit"), reply_markup: {
      inline_keyboard: [[{ text: DONE_EDIT, callback_data: "DONE_EDIT" }]] + [
        ([ before_page ] +
          @customer.draft_order.images.order(created_at: :asc).to_a[((page - 1) * page_size), page_size].map.with_index do |image, index|
            { text: ((page - 1) * page_size + index + 1).to_s, callback_data: "DELETE_IMAGE_#{image.id}_#{(page - 1) * page_size + index + 1}" }
          end + [ next_page ]).compact
      ]
    }
  end

  def shipping_query(data = nil)
    @customer.draft_order.update({
      country_code: data["shipping_address"]["country_code"],
      address1: data["shipping_address"]["street_line1"],
      address2: data["shipping_address"]["street_line2"],
      address_town_or_city: data["shipping_address"]["city"],
      state_or_county: data["shipping_address"]["state"],
      postal_or_zip_code: data["shipping_address"]["post_code"],
    })

    options = {
      shipping_options: @customer.draft_order.shipping_options.map do |shipping_option|
        {
          id: shipping_option["pwinty_shipping_method"],
          title: "#{shipping_option["shipping_method"]} - ETA #{shipping_option["estimated_arrival_date"].strftime("%b %d")}",
          prices: [
            {
              label: "#{shipping_option["shipping_method"]} shipping",
              amount: shipping_option["usd_price"].to_s
            }
          ]
        }
      end
    }
    answer_shipping_query(true, options)
  end

  def pre_checkout_query(data = nil)
    @customer.draft_order.update({
      country_code: data["order_info"]["shipping_address"]["country_code"],
      address1: data["order_info"]["shipping_address"]["street_line1"],
      address2: data["order_info"]["shipping_address"]["street_line2"],
      address_town_or_city: data["order_info"]["shipping_address"]["city"],
      state_or_county: data["order_info"]["shipping_address"]["state"],
      postal_or_zip_code: data["order_info"]["shipping_address"]["post_code"],
      preferred_shipping_method: data["shipping_option_id"],
      customer_name: data["order_info"]["name"],
      final_price: data["total_amount"],
      currency: data["currency"],
      state: "ongoing"
    })

    answer_pre_checkout_query(true, {})
  rescue => error
    ExceptionNotifier.notify_exception(error)

    answer_pre_checkout_query(false, { error_message: "There was an unexpected error with your order, please try again later."})
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

  def set_customer_chat_reference
    if chat.present? && chat["id"].present?
      @customer.update(chat_reference: chat["id"])
    end
  end

  def add_sticker(sticker_message)
    if @customer.draft_order.images.where(telegram_reference: sticker_message["file_id"]).count >= Rails.configuration.sticker_limit
      raise StickerLimitReached
    else
      Image.create!(
        order: @customer.draft_order,
        product: @product,
        telegram_reference: sticker_message["file_id"],
      )
    end
  end
end
