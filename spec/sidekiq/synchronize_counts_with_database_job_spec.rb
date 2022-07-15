require 'rails_helper'
RSpec.describe "Sidekiq job", type: :job do
  let!(:application) { create(:application) }
  let!(:chat) { create(:chat, application_id: application.id) }
  describe "Synchronize counts with database job" do
    before do
      RedisHandlerService.update_hash("chats_count:#{application.id}")
      RedisHandlerService.update_hash("messages_count:#{chat.id}")
      SynchronizeRedisWithDatabaseJob.perform_async(1, 2)
      SynchronizeRedisWithDatabaseJob.perform_one
    end
    context 'when synchronize counts job is queued' do
      it 'should update chats_count column for application table after job is executed' do
        expect(Application.find(application.id).chats_count).to eq(1)
      end
      it 'should update messages_count column for chat table after job is executed' do
        expect(Chat.find(chat.id).messages_count).to eq(1)
      end
      it 'should update is_flushed_to_db flag in redis for chats_count key' do
        expect(RedisHandlerService.get_hash_values("chats_count:#{application.id}")[1]).to eq("true")
      end
      it 'should update is_flushed_to_db flag in redis for messages_count key' do
        expect(RedisHandlerService.get_hash_values("chats_count:#{application.id}")[1]).to eq("true")
      end

      it 'should clear jobs queue' do
        expect(SynchronizeRedisWithDatabaseJob.jobs.size).to eq(0)

      end
    end
  end

end
