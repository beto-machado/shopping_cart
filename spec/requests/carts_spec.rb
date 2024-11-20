require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let!(:product) { create(:product, name: "Product 1", price: 10.0) }
  let!(:cart) { create(:cart) }
  let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 2) }

  before do
    request.set_cookie['_store_session'] = cart.id
  end

  describe 'GET #show' do
    context 'when cart exists' do
      it 'returns the cart with its products' do
        get '/cart'
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(cart.id)
        expect(json_response['products'].length).to eq(1)
        expect(json_response['total_price']).to eq(20.0)
      end
    end

    context 'when cart does not exist' do

      it 'returns an error' do
        get :show
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Cart not found')
      end
    end
  end

  pending "TODO: Escreva os testes de comportamento do controller de carrinho necessários para cobrir a sua implmentação #{__FILE__}"
  describe "POST /add_items" do
    let(:cart) { Cart.create }
    let(:product) { Product.create(name: "Test Product", price: 10.0) }
    let!(:cart_item) { CartItem.create(cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end
    end
  end
end
