FactoryBot.define do
  factory :chat do
    number { Faker::Number.number(digits: 3) }
    messages_count { Faker::Number.number(digits: 3) }
    application_id { nil }
  end
end