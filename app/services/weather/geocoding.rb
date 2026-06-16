# frozen_string_literal: true

module Weather
  class Geocoding
    def call(address)
      raise AddressNotFound, "Address can't be blank" if address.to_s.strip.empty?

      result = Geocoder.search(address).first
      raise AddressNotFound, "Could not resolve address: #{address.inspect}" if result.nil?

      zip = result.postal_code.presence
      raise AddressNotFound, "No postal code found for: #{address.inspect}" if zip.nil?

      Location.new(
        address: address,
        zip: zip,
        latitude: result.latitude,
        longitude: result.longitude
      )
    rescue Geocoder::Error => e
      raise ForecastUnavailable, "Geocoding service error: #{e.message}"
    end
  end
end
