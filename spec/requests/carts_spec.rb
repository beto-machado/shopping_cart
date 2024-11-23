require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let(:product_1) { create(:product, name: "Product 1", price: 10.0) }
  let(:product_2) { create(:product, name: "Product 2", price: 20.0) }
  let(:cart) { create(:cart) }
  let!(:cart_item) { create(:cart_item, cart: cart, product: product_1, quantity: 2) }
  
  before do
    allow_any_instance_of(CartsController).to receive(:session).and_return({ cart_id: cart.id })
  end

  describe 'GET /cart' do
    it 'returns the cart with products' do
      get "/cart"

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(cart.id)
      expect(json_response['products'].length).to eq(1)
      expect(json_response['products'].first['id']).to eq(product_1.id)
      expect(json_response['products'].first['name']).to eq(product_1.name)
      expect(json_response['products'].first['unit_price']).to eq(product_1.price)
      expect(json_response['total_price']).to eq(20.0)
    end

    it 'returns 404 if cart is not found' do
      allow_any_instance_of(CartsController).to receive(:session).and_return({ cart_id: nil })
      
      get "/cart"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq("Cart not found")
    end
  end

  describe 'POST /cart' do
    it 'adds a product to the cart' do
      post "/cart", params: { product_id: product_2.id, quantity: 1 }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(cart.id)
      expect(json_response['products'].length).to eq(2)
      expect(json_response['products'].first['name']).to eq('Product 1')
      expect(json_response['products'].first['unit_price']).to eq(10)
      expect(json_response['products'].first['quantity']).to eq(2)
      expect(json_response['products'].second['name']).to eq('Product 2')
      expect(json_response['products'].second['unit_price']).to eq(20)
      expect(json_response['products'].second['quantity']).to eq(1)
      expect(json_response['total_price']).to eq(40.0)
    end

    it 'returns an error if the product is already in the cart' do
      post "/cart", params: { product_id: product_1.id, quantity: 1 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq("Product already exists in the cart")
    end
  end

  describe "POST /add_item" do
    it 'updates the quantity of the existing item in the cart' do
      post '/cart/add_item', params: { product_id: product_1.id, quantity: 1 }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['products'].first['quantity']).to eq(3)
    end

    it 'returns an error if the product is not in the cart' do
      post "/cart/add_item", params: { product_id: 999, quantity: 2 }

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq("Product not found in cart")
    end

    it 'returns an error if product if quantity is negative' do
      post "/cart/add_item", params: { product_id: product_1.id, quantity: -1 }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq("Product not found in cart")
    end
  end

  describe 'DELETE /cart/remove_product' do
    it 'removes a product from the cart' do
      delete "/cart/#{ product_1.id }"

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(cart.id)
      expect(json_response['products']).to be_empty
      expect(json_response['total_price']).to eq(0)
    end

    it 'returns an error if the product is not found in the cart' do
      delete "/cart/99"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq("Product not found in cart")
    end
  end
end
