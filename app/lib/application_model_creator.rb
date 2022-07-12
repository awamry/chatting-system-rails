require "securerandom"
class ApplicationModelCreator
  def self.create(application_params)
    application = Application.new(application_params)
    application.token = SecureRandom.uuid
    application.chats_count = 0
    raise ActiveRecord::RecordInvalid.new(application) unless application.valid?
    return application
  end
end