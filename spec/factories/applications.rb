FactoryBot.define do
  factory :application do
    name { Faker::Lorem.word }
    token { Faker::Alphanumeric.alphanumeric(number: 26) }
    chats_count {Faker::Number.number(digits: 3)}
  end
end