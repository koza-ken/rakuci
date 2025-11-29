GOOGLE_MAPS_API_KEY =
  ENV["GOOGLE_MAPS_API_KEY"] ||
  Rails.application.credentials.google_maps&.[](:api_key)
