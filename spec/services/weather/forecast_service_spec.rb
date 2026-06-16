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

  it "does not swallow geocoding errors" do
    allow(geocoding).to receive(:call).and_raise(Weather::AddressNotFound)

    expect { service.call("bad") }.to raise_error(Weather::AddressNotFound)
  end
end
