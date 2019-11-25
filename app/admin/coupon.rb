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

  member_action :page, method: :get do
    @coupon = Coupon.find(params[:id])

    respond_to do |format|
      format.html do
        render "admin/coupons/page.pdf.slim", layout: "application.html.slim"
      end

      format.pdf do
        render({
          pdf: "admin/coupons/page",
          layout: "application.html.slim",
          file_name: "coupon_#{params[:id]}.pdf",
          page_size: "A4",
          show_as_html: params.key?('debug'),
        })
      end
    end
  end

  action_item :page, only: [:show, :edit] do
    link_to "Page", page_admin_coupon_path(id: params[:id], format: "pdf")
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
