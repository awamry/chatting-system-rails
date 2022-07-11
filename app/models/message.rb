class Message < ApplicationRecord
  belongs_to :chat

  validates_presence_of :number, :content, :chat_id
end
