class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    carts = Cart.where(status: 'active').where('last_interaction_at < ?', 3.hours.ago)
    carts.each do |cart|
      cart.mark_as_abandoned
    end

    abandoned_carts = Cart.where(status: 'abandoned').where('last_interaction_at < ?', 7.days.ago)
    abandoned_carts.each do |cart|
      cart.destroy
    end
  end
end
