class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    Cart.where(status: 'active').where('last_interaction_at < ?', 3.hours.ago).each do |cart|
      cart.mark_as_abandoned
    end
  
    Cart.where(status: 'abandoned').where('last_interaction_at < ?', 7.days.ago).each do |cart|
      cart.remove_if_abandoned
    end
  end
end
