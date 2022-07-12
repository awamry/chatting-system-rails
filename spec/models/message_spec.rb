require 'rails_helper'

# Test suite for the Message model
RSpec.describe Message, type: :model do
  it { should belong_to(:chat) }
  it { should validate_presence_of(:number) }
  it { should validate_presence_of(:body) }
  it { should validate_presence_of(:chat_id) }
end