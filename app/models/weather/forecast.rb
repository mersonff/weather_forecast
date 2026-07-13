# frozen_string_literal: true

module Weather
  Forecast = Data.define(
    :zip,
    :current_temperature,
    :high,
    :low,
    :unit,
    :observed_at,
    :daily
  )
end
