FactoryBot.define do
  factory :message do
    number { Faker::Number.number(digits: 3) }
    content { Faker::Lorem.word }
    chat_id { nil }
  end
end