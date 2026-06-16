# frozen_string_literal: true

require "net/http"
require "json"

module Weather
  class Client
    BASE_URL = "https://api.open-meteo.com/v1/forecast"
    DEFAULT_UNIT = "fahrenheit"
    FORECAST_DAYS = 5
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5

    def initialize(unit: DEFAULT_UNIT, forecast_days: FORECAST_DAYS)
      @unit = unit
      @forecast_days = forecast_days
    end

    def call(latitude:, longitude:, zip:)
      body = fetch(latitude:, longitude:)
      build_forecast(zip:, body:)
    end

    private

    def fetch(latitude:, longitude:)
      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form(
        latitude: latitude,
        longitude: longitude,
        current: "temperature_2m",
        daily: "temperature_2m_max,temperature_2m_min",
        temperature_unit: @unit,
        timezone: "auto",
        forecast_days: @forecast_days
      )

      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT
      ) { |http| http.get(uri.request_uri) }

      unless response.is_a?(Net::HTTPSuccess)
        raise ForecastUnavailable, "Weather provider returned #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ForecastUnavailable, "Invalid response from weather provider: #{e.message}"
    rescue Timeout::Error, SocketError, SystemCallError => e
      raise ForecastUnavailable, "Weather provider unreachable: #{e.message}"
    end

    def build_forecast(zip:, body:)
      current = body.fetch("current")
      units = body.fetch("current_units")
      daily = body.fetch("daily")

      Forecast.new(
        zip: zip,
        current_temperature: current.fetch("temperature_2m"),
        high: daily.fetch("temperature_2m_max").first,
        low: daily.fetch("temperature_2m_min").first,
        unit: units.fetch("temperature_2m"),
        observed_at: Time.zone.parse(current.fetch("time")),
        daily: build_daily(daily)
      )
    rescue KeyError => e
      raise ForecastUnavailable, "Unexpected response shape: missing #{e.message}"
    end

    def build_daily(daily)
      dates = daily.fetch("time")
      highs = daily.fetch("temperature_2m_max")
      lows = daily.fetch("temperature_2m_min")

      dates.each_index.map do |i|
        DailyForecast.new(date: Date.parse(dates[i]), high: highs[i], low: lows[i])
      end
    end
  end
end
