# frozen_string_literal: true

module Weather
  class Geocoding
    POSTAL_CODE = /\b\d{5}(?:-?\d{3,4})?\b/

    def call(address)
      raise AddressNotFound, "Address can't be blank" if address.to_s.strip.empty?

      result = search(address)
      raise AddressNotFound, "Could not resolve address: #{address.inspect}" if result.nil?

      Location.new(
        address: address,
        zip: result.postal_code.presence,
        latitude: result.latitude,
        longitude: result.longitude
      )
    rescue Geocoder::Error => e
      raise ForecastUnavailable, "Geocoding service error: #{e.message}"
    end

    private

    def search(address)
      Geocoder.search(address).first || search_by_postal_code(address)
    end

    def search_by_postal_code(address)
      postal_code = address.to_s[POSTAL_CODE]
      return if postal_code.nil?

      Geocoder.search(postal_code).first
    end
  end
end
