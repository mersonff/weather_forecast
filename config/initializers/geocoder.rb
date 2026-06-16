# frozen_string_literal: true

Geocoder.configure(
  lookup: :nominatim,
  timeout: 5,
  units: :mi,
  http_headers: {
    "User-Agent" => "weather_forecast assessment app (https://github.com/)"
  }
)
