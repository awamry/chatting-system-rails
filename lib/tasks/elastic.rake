namespace :es do
  desc "Build elastic index"
  task :build_index => :environment do
    Message.__elasticsearch__.create_index!
  end
end