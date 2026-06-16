# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::Client do
  subject(:client) { described_class.new }

  let(:payload) do
    {
      "current" => { "time" => "2026-06-15T12:00", "temperature_2m" => 70.3 },
      "current_units" => { "temperature_2m" => "°F" },
      "daily" => {
        "time" => [ "2026-06-15", "2026-06-16" ],
        "temperature_2m_max" => [ 76.0, 78.1 ],
        "temperature_2m_min" => [ 64.6, 65.0 ]
      }
    }.to_json
  end

  it "maps the provider payload into a Forecast" do
    stub_request(:get, /api\.open-meteo\.com/)
      .to_return(status: 200, body: payload, headers: { "Content-Type" => "application/json" })

    forecast = client.call(latitude: 40.7, longitude: -73.9, zip: "10118")

    expect(forecast).to have_attributes(
      zip: "10118",
      current_temperature: 70.3,
      high: 76.0,
      low: 64.6,
      unit: "°F"
    )
    expect(forecast.daily.size).to eq(2)
    expect(forecast.daily.first)
      .to have_attributes(date: Date.new(2026, 6, 15), high: 76.0, low: 64.6)
  end

  it "raises ForecastUnavailable on a non-success response" do
    stub_request(:get, /api\.open-meteo\.com/).to_return(status: 500, body: "boom")

    expect { client.call(latitude: 1, longitude: 2, zip: "00000") }
      .to raise_error(Weather::ForecastUnavailable, /500/)
  end

  it "raises ForecastUnavailable on malformed JSON" do
    stub_request(:get, /api\.open-meteo\.com/).to_return(status: 200, body: "not json")

    expect { client.call(latitude: 1, longitude: 2, zip: "00000") }
      .to raise_error(Weather::ForecastUnavailable)
  end
end
