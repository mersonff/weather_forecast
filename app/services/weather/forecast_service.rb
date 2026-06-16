# frozen_string_literal: true

module Weather
  class ForecastService
    FORECAST_TTL = 30.minutes
    GEOCODE_TTL = 1.day

    def initialize(unit: Client::DEFAULT_UNIT, geocoding: Geocoding.new, client: Client.new(unit:), cache: Rails.cache)
      @unit = unit
      @geocoding = geocoding
      @client = client
      @cache = cache
    end

    def call(address)
      location = geocode(address)
      key = forecast_cache_key(location.zip)

      if (cached = @cache.read(key))
        return Result.new(location:, forecast: cached, from_cache: true)
      end

      forecast = @client.call(
        latitude: location.latitude,
        longitude: location.longitude,
        zip: location.zip
      )
      @cache.write(key, forecast, expires_in: FORECAST_TTL)
      Result.new(location:, forecast:, from_cache: false)
    end

    private

    def geocode(address)
      @cache.fetch(geocode_cache_key(address), expires_in: GEOCODE_TTL) do
        @geocoding.call(address)
      end
    end

    def forecast_cache_key(zip)
      "weather/forecast/#{zip}/#{@unit}"
    end

    def geocode_cache_key(address)
      "weather/geocode/#{address.to_s.strip.downcase}"
    end
  end
end
