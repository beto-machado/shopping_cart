class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  validate :quantity_must_be_positive

  enum status: { active: 'active', abandoned: 'abandoned' }

  def add_product(product_id, quantity)
    product = Product.find(product_id)
    cart_item = cart_items.find_by(product_id: product_id)

    if cart_item
      raise "Product already exists in the cart"
    else
      cart_items.create!(product: product, quantity: quantity)
    end

    update_cart_total
    update_last_interaction
  end

  def remove_product(product_id)
    cart_item = cart_items.find_by(product_id: product_id)
    if cart_item
      cart_item.destroy
      update_cart_total
      update_last_interaction
    else
      raise "Product not found in cart"
    end
  end

  def update_product_quantity(product_id, quantity)
    cart_item = cart_items.find_by(product_id: product_id)
    if cart_item
      cart_item.update(quantity: cart_item.quantity + quantity)
      update_cart_total
      update_last_interaction
    else
      raise "Product not found in cart"
    end
  end

  def update_last_interaction
    update!(last_interaction_at: Time.current)
  end

  def mark_as_abandoned
    update!(status: :abandoned)
  end

  private

  def update_cart_total
    total_price = cart_items.includes(:product).sum { |item| item.quantity * item.product.price }
    update!(total_price: total_price)
  end

  def quantity_must_be_positive
    if cart_items.any? { |item| item.quantity < 0 }
      errors.add(:base, "Quantity cannot be negative")
    end
  end
end
