require 'rails_helper'

# Test suite for the Chat model
RSpec.describe Chat, type: :model do
  it { should belong_to(:application) }
  it { should validate_presence_of(:number) }
  it { should validate_presence_of(:messages_count) }
  it { should validate_presence_of(:application_id) }
end