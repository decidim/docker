def env_enabled?(env_name, default_value = "disabled")
  ["true", "1", "enabled"].include? ENV.fetch(env_name, default_value)
end