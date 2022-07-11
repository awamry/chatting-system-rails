class Chat < ApplicationRecord
  belongs_to :application

  validates_presence_of :number, :messages_count, :application_id
end
