# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::Client, :vcr do
  it "fetches a real forecast from Open-Meteo and matches our expected shape" do
    forecast = described_class.new.call(latitude: 40.748, longitude: -73.985, zip: "10118")

    expect(forecast.zip).to eq("10118")
    expect(forecast.current_temperature).to be_a(Numeric)
    expect(forecast.unit).to be_present
    expect(forecast.daily).to all(be_a(Weather::DailyForecast))
    expect(forecast.daily.size).to be > 1
  end
end
