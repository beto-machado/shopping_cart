require 'rails_helper'

RSpec.describe Cart, type: :model do
  describe 'associations' do
    it { should have_many(:cart_items) }
    it { should have_many(:products).through(:cart_items) }
  end

  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'mark_as_abandoned' do
    let(:cart) { create(:cart) }

    it 'marks the cart as abandoned if inactive for a certain time' do
      cart.update(last_interaction_at: 3.hours.ago)
      expect { cart.mark_as_abandoned }.to change { cart.abandoned? }.from(false).to(true)
    end
  end

  describe 'remove_if_abandoned' do
    let(:cart) { create(:cart, last_interaction_at: 7.days.ago) }

    it 'removes the cart if abandoned for a certain time' do
      cart.mark_as_abandoned
      expect { cart.remove_if_abandoned }.to change { Cart.count }.by(-1)
    end
  end

  describe '#add_product' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }

    context 'when the product does not exist in the cart' do
      it 'adds the product to the cart with the specified quantity' do
        expect {
          cart.add_product(product.id, 2)
        }.to change { cart.cart_items.count }.by(1)

        cart_item = cart.cart_items.find_by(product_id: product.id)
        expect(cart_item).not_to be_nil
        expect(cart_item.quantity).to eq(2)
      end
    end

    context 'when the product already exists in the cart' do
      before do
        cart.cart_items.create!(product: product, quantity: 1)
      end

      it 'raises an error' do
        expect {
          cart.add_product(product.id, 2)
        }.to raise_error("Product already exists in the cart")
      end

      it 'does not add a duplicate product to the cart' do
        expect {
          begin
            cart.add_product(product.id, 2)
          rescue
          end
        }.not_to change { cart.cart_items.count }
      end
    end
  end

  describe '#remove_product' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }

    context 'when the product exists in the cart' do
      let!(:cart_item) { cart.cart_items.create!(product: product, quantity: 2) }

      it 'removes the product from the cart' do
        expect {
          cart.remove_product(product.id)
        }.to change { cart.cart_items.count }.by(-1)
      end

      it 'updates the cart total' do
        allow(cart).to receive(:update_cart_total)
        cart.remove_product(product.id)
        expect(cart).to have_received(:update_cart_total)
      end
    end

    context 'when the product does not exist in the cart' do
      it 'raises an error' do
        expect {
          cart.remove_product(product.id)
        }.to raise_error("Product not found in cart")
      end

      it 'does not affect the cart items' do
        expect {
          begin
            cart.remove_product(product.id)
          rescue
          end
        }.not_to change { cart.cart_items.count }
      end
    end
  end

  describe '#update_product_quantity' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }

    context 'when the product exists in the cart' do
      let!(:cart_item) { cart.cart_items.create!(product: product, quantity: 2) }

      it 'updates the product quantity correctly' do
        expect {
          cart.update_product_quantity(product.id, 3)
        }.to change { cart_item.reload.quantity }.from(2).to(5)
      end
    end

    context 'when the product does not exist in the cart' do
      it 'raises an error' do
        expect {
          cart.update_product_quantity(product.id, 3)
        }.to raise_error("Product not found in cart")
      end

      it 'does not affect other cart items' do
        other_cart_item = cart.cart_items.create!(product: create(:product), quantity: 1)
        expect {
          begin
            cart.update_product_quantity(product.id, 3)
          rescue
          end
        }.not_to change { other_cart_item.reload.quantity }
      end
    end
  end

  describe '#update_cart_total' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }
    let!(:cart_item) { cart.cart_items.create!(product: product, quantity: 2) }

    it 'updates the cart total' do
      allow(cart).to receive(:update_cart_total)
      cart.update_product_quantity(product.id, 3)
      expect(cart).to have_received(:update_cart_total)
    end
  end

  describe '#update_last_interaction' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }
    let!(:cart_item) { cart.cart_items.create!(product: product, quantity: 2) }

    it 'updates the last interaction time' do
      allow(cart).to receive(:update_last_interaction)
      cart.update_product_quantity(product.id, 3)
      expect(cart).to have_received(:update_last_interaction)
    end
  end

  describe '#quantity_must_be_positive' do
    let(:cart) { create(:cart) }

    it 'when all cart item quantities are positive' do
      cart.cart_items.create!(product: create(:product), quantity: 1)
      cart.cart_items.create!(product: create(:product), quantity: 5)
      expect(cart).to be_valid
    end

    it 'when at least one cart item has a negative quantity' do
      cart.cart_items.create!(product: create(:product), quantity: 1)
      cart.cart_items.build(product: create(:product), quantity: -3)

      expect(cart).not_to be_valid
      expect(cart.errors[:base]).to include("Quantity cannot be negative")
    end
  end
end
