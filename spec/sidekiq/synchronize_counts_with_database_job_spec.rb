require 'rails_helper'
RSpec.describe "Sidekiq job", type: :job do
  it 'pushes sidekiq to the queue' do
    assert_equal 0, SynchronizeRedisWithDatabaseJob.jobs.size
    SynchronizeRedisWithDatabaseJob.perform_async(1, 2)
    assert_equal 1, SynchronizeRedisWithDatabaseJob.jobs.size
  end

  it 'executes sidekiq jobs pushed to the queue' do
    SynchronizeRedisWithDatabaseJob.perform_async(1, 2)
    SynchronizeRedisWithDatabaseJob.perform_async(2, 3)
    assert_equal 2, SynchronizeRedisWithDatabaseJob.jobs.size
    SynchronizeRedisWithDatabaseJob.drain
    assert_equal 0, SynchronizeRedisWithDatabaseJob.jobs.size
  end


end
