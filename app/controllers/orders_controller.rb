class OrdersController < ApplicationController
  def new
  end

  def edit
    @order = Order.find_by_token(params[:token])
  end
end
