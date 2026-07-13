# frozen_string_literal: true

module Weather
  Result = Data.define(:location, :forecast, :from_cache) do
    def from_cache? = from_cache
  end
end
