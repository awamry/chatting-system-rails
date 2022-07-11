class Application < ApplicationRecord
  has_many :chats, dependent: :destroy

  validates_presence_of :name, :token, :chats_count
end
