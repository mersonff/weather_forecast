# frozen_string_literal: true

module Weather
  Error = Class.new(StandardError)
  AddressNotFound = Class.new(Error)
  ForecastUnavailable = Class.new(Error)
end
