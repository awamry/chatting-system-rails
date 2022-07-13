FactoryBot.define do
  factory :message do
    number { Faker::Number.number(digits: 15) }
    body { Faker::Lorem.word }
    chat_id { nil }
  end
end