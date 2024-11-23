require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    let(:cart_active) { create(:cart, last_interaction_at: 4.hours.ago) }
    let(:cart_active_recent) { create(:cart, last_interaction_at: 2.hours.ago) }
    let(:cart_abandoned) { create(:cart, status: 'abandoned', last_interaction_at: 8.days.ago) }
    let(:cart_abandoned_recent) { create(:cart, status: 'abandoned', last_interaction_at: 5.days.ago) }

    it 'marks active carts as abandoned if last interaction was more than 3 hours ago' do
      expect { MarkCartAsAbandonedJob.new.perform }
        .to change { cart_active.reload.status }.from('active').to('abandoned')
    end

    it 'does not mark active carts as abandoned if last interaction was less than 3 hours ago' do

      expect { MarkCartAsAbandonedJob.new.perform }
        .not_to change { cart_active_recent.reload.status }
    end

    it 'removes abandoned carts if last interaction was more than 7 days ago' do
      expect { MarkCartAsAbandonedJob.new.perform }
        .to change { Cart.exists?(cart_abandoned.id) }.from(true).to(false)
    end

    it 'does not remove abandoned carts if last interaction was less than 7 days ago' do
      expect { MarkCartAsAbandonedJob.new.perform }
        .not_to change { Cart.exists?(cart_abandoned_recent.id) }
    end
  end
end

