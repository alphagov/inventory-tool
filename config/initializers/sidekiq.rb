redis_url = Rails.env.development? ? 'redis://localhost:6379/0' : ENV['REDISTOGO_URL']


# Uncomment this block and restart the server to get the sidekiq jobs to be executed 
# immediately as part of the request cycle
#
# if Rails.env.development?
#   require 'sidekiq/testing'
#   Sidekiq::Testing.inline!
# end

Sidekiq.configure_server do |config|
  config.redis = { :url => redis_url, :size => 4 }
end

Sidekiq.configure_client do |config|
  config.redis = { :url => redis_url, :size => 1 }
end


