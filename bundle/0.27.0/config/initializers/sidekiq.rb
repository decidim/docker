
Sidekiq.configure_server do |config|
    config.redis = { 
      host: ENV.fetch("JOB_HOST") { "redis" },
      port: ENV.fetch("JOB_PORT") { "6379" }.to_i,
      db: ENV.fetch("JOB_DB") { "2" }.to_i,
      username: ENV.fetch("JOB_USERNAME") { "default" },
      password: ENV.fetch("JOB_PASSWORD") { "insecure-password" }
    }
end

Sidekiq.configure_client do |config|
    config.redis = { 
      host: ENV.fetch("JOB_HOST") { "redis" },
      port: ENV.fetch("JOB_PORT") { "6379" }.to_i,
      db: ENV.fetch("JOB_DB") { "2" }.to_i,
      username: ENV.fetch("JOB_USERNAME") { "default" },
      password: ENV.fetch("JOB_PASSWORD") { "insecure-password" }
    }
end
