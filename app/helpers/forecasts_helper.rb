# frozen_string_literal: true

module ForecastsHelper
  def temperature(value, unit)
    "#{value.round}#{unit}"
  end
end
