FactoryBot.define do
  factory :message do
    number { Faker::Number.number(digits: 3) }
    body { Faker::Lorem.word }
    chat_id { nil }
  end
end