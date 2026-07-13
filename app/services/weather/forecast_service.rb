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
      forecast, from_cache = read_or_fetch(forecast_cache_key(location)) do
        @client.call(
          latitude: location.latitude,
          longitude: location.longitude,
          zip: location.zip
        )
      end
      Result.new(location:, forecast:, from_cache:)
    end

    private

    def geocode(address)
      @cache.fetch(geocode_cache_key(address), expires_in: GEOCODE_TTL) do
        @geocoding.call(address)
      end
    end

    def read_or_fetch(key)
      if (cached = @cache.read(key))
        [ cached, true ]
      else
        value = yield
        @cache.write(key, value, expires_in: FORECAST_TTL)
        [ value, false ]
      end
    end

    def forecast_cache_key(location)
      region = location.zip.presence || format("%.2f,%.2f", location.latitude, location.longitude)
      "weather/forecast/#{region}/#{@unit}"
    end

    def geocode_cache_key(address)
      "weather/geocode/#{address.to_s.strip.downcase}"
    end
  end
end
