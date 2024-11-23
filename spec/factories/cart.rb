FactoryBot.define do
  factory :cart do
    total_price { Faker::Commerce.price(range: 1.0..100.0) }
    status { 'active' }
    last_interaction_at { Time.current }
  end
end
