ActiveAdmin.register Order do
  permit_params [
    :country_code,
    :customer_name,
    :state,
    :created_at,
    :updated_at,
    :address1,
    :address2,
    :address_town_or_city,
    :state_or_county,
    :postal_or_zip_code,
    :preferred_shipping_method,
    :customer_id,
    :coupon_id,
    images_attributes: [:document, :created_at, :updated_at]
  ]

  member_action :pwinty_data, method: :get do
    @pwinty_data = JSON.parse(Pwinty.get_order(Order.find(params[:id])).body)
  end

  member_action :pwinty_validation, method: :get do
    @pwinty_validation = JSON.parse(Pwinty.validate_order(Order.find(params[:id])).body)
  end

  member_action :submit, method: :get do
    @pwinty_response = JSON.parse(Pwinty.update_order_status(Order.find(params[:id]), { status: "Submitted" }).body)
  end

  member_action :cancel, method: :get do
    @pwinty_response = JSON.parse(Pwinty.update_order_status(Order.find(params[:id]), { status: "Cancelled" }).body)
  end

  action_item :pwinty_data, only: [:show, :edit] do
    link_to "Pwinty data", pwinty_data_admin_order_path(id: params[:id])
  end

  action_item :validation, only: [:show, :edit] do
    link_to "Validation", pwinty_validation_admin_order_path(id: params[:id])
  end

  action_item :submit, only: [:show, :edit] do
    link_to "Submit", submit_admin_order_path(id: params[:id]), data: { confirm: "Are you sure you want to submit this order?"}
  end

  action_item :cancel, only: [:show, :edit] do
    link_to "Cancel", cancel_admin_order_path(id: params[:id]), data: { confirm: "Are you sure you want to cancel this order?"}
  end

  index do
    selectable_column
    id_column
    column :customer_name
    column :state
    column :created_at
    actions
  end

  show do
    panel "Record info" do
      attributes_table_for order do
        row :id
      end
    end

    panel "Order info" do
      attributes_table_for order do
        row :country_code
        row :customer_name
        row :state
        row :customer_id
        row :created_at
        row :updated_at
        row :address1
        row :address2
        row :address_town_or_city
        row :state_or_county
        row :postal_or_zip_code
        row :preferred_shipping_method
        row :pwinty_reference
        row :currency
        row :final_price
        row :telegram_payment_charge_reference
        row :provider_payment_charge_reference
        row :closed_at
      end
    end
  end


  form do |f|
    f.inputs "Associations" do
      f.input :customer
      f.input :coupon
    end

    f.inputs "Order Details" do
      f.input :country_code
      f.input :customer_name
      f.input :state
      f.input :created_at
      f.input :updated_at
      f.input :address1
      f.input :address2
      f.input :address_town_or_city
      f.input :state_or_county
      f.input :postal_or_zip_code
      f.input :preferred_shipping_method

      f.has_many :images, allow_destroy: true do |i|
        i.input :id, as: "hidden"
        i.input :document, as: :file, :hint => i.object.document.attached? ? image_tag(url_for(i.object.document)) : nil

        i.input :created_at
        i.input :updated_at
      end

    end
    f.actions
  end
end
