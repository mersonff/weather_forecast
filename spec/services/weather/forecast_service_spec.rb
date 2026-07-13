# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::ForecastService do
  subject(:service) { described_class.new(geocoding:, client:, cache:) }

  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:location) do
    Weather::Location.new(address: "somewhere", zip: "10118", latitude: 1.0, longitude: 2.0)
  end
  let(:forecast) do
    Weather::Forecast.new(
      zip: "10118", current_temperature: 70.0, high: 76.0, low: 64.0,
      unit: "°F", observed_at: Time.current, daily: []
    )
  end
  let(:geocoding) { instance_double(Weather::Geocoding, call: location) }
  let(:client) { instance_double(Weather::Client, call: forecast) }

  it "fetches fresh on the first call and flags from_cache as false" do
    result = service.call("somewhere")

    expect(result.from_cache?).to be(false)
    expect(result.forecast).to eq(forecast)
    expect(result.location).to eq(location)
  end

  it "serves the second call for the same zip from cache without re-fetching" do
    service.call("somewhere")
    result = service.call("somewhere")

    expect(result.from_cache?).to be(true)
    expect(client).to have_received(:call).once
  end

  it "caches by zip, so a different address resolving to the same zip is a cache hit" do
    other = Weather::Location.new(address: "other", zip: "10118", latitude: 9.0, longitude: 9.0)
    allow(geocoding).to receive(:call).with("first").and_return(location)
    allow(geocoding).to receive(:call).with("second").and_return(other)

    service.call("first")
    result = service.call("second")

    expect(result.from_cache?).to be(true)
    expect(client).to have_received(:call).once
  end

  it "caches by coordinates when the location has no postal code" do
    city = Weather::Location.new(address: "São Paulo", zip: nil, latitude: -23.55, longitude: -46.63)
    allow(geocoding).to receive(:call).and_return(city)

    service.call("São Paulo")
    result = service.call("São Paulo")

    expect(result.from_cache?).to be(true)
    expect(client).to have_received(:call).once
  end

  it "does not swallow geocoding errors" do
    allow(geocoding).to receive(:call).and_raise(Weather::AddressNotFound)

    expect { service.call("bad") }.to raise_error(Weather::AddressNotFound)
  end

  it "writes the forecast to the cache once and reads it back on the next call" do
    key = "weather/forecast/10118/#{Weather::Client::DEFAULT_UNIT}"
    allow(cache).to receive(:read).and_call_original
    allow(cache).to receive(:write).and_call_original

    service.call("somewhere")
    service.call("somewhere")

    expect(cache).to have_received(:write).with(key, forecast, expires_in: described_class::FORECAST_TTL).once
    expect(cache).to have_received(:read).with(key).twice
  end
end
