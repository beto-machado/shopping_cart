FactoryBot.define do
  factory :cart do
    total_price { Faker::Commerce.price(range: 1.0..100.0) }
  end
end
