if(Rails.env.development? and Settings.redis_development_caching)
  Positronic::Application.config.cache_store = :redis_store, "redis://localhost:6379/1"
end
