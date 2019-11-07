ActiveAdmin.register Coupon do
  permit_params [
    :code,
    :count,
    :product_id
  ]

  index do
    selectable_column
    id_column
    column :code
    column :count
    column :order
    column :created_at
    actions
  end

  form do |f|
    f.inputs "Associations" do
      f.input :product
    end

    f.inputs "Order Details" do
      f.input :code
      f.input :count
    end
    f.actions
  end
end
