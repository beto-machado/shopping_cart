class CartsController < ApplicationController
  before_action :set_cart, only: %i[show add_item remove_product]

  def show
    if @cart
      render json: cart_response(@cart), status: :ok
    else
      render json: { error: "Cart not found" }, status: :not_found
    end
  end

  def add_product
    cart = find_or_create_cart
    begin
      cart.add_product(params[:product_id].to_i, params[:quantity].to_i)
      render json: cart_response(cart), status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def add_item
    begin
      existing_product = @cart.cart_items.find_by(product_id: params[:product_id].to_i)
      
      if existing_product.nil?
        raise StandardError, "Product not found in cart"
      end
  
      @cart.update_product_quantity(existing_product.product_id, params[:quantity].to_i)
      render json: cart_response(@cart), status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  

  def remove_product
    begin
      @cart.remove_product(params[:product_id].to_i)
      render json: cart_response(@cart), status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :not_found
    end
  end

  private

  def set_cart
    @cart = Cart.find_by(id: session[:cart_id])
  end

  def find_or_create_cart
    Cart.find_by(id: session[:cart_id]) || create_new_cart
  end

  def create_new_cart
    cart = Cart.create!(total_price: 0)
    session[:cart_id] = cart.id
    cart
  end

  def cart_response(cart)
    {
      id: cart.id,
      products: cart.cart_items.map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.product.price.to_f,
          total_price: (item.quantity * item.product.price.to_f).round(2)
        }
      end,
      total_price: cart.cart_items.sum { |item| (item.quantity * item.product.price.to_f).round(2) }
    }
  end
end
