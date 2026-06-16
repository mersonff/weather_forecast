# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  let(:weather_payload) do
    {
      "current" => { "time" => "2026-06-15T12:00", "temperature_2m" => 70.3 },
      "current_units" => { "temperature_2m" => "°F" },
      "daily" => {
        "time" => [ "2026-06-15" ],
        "temperature_2m_max" => [ 76.0 ],
        "temperature_2m_min" => [ 64.6 ]
      }
    }.to_json
  end

  before do
    Geocoder::Lookup::Test.add_stub(
      "350 Fifth Ave, New York, NY",
      [ { "latitude" => 40.748, "longitude" => -73.985, "postal_code" => "10118" } ]
    )
    stub_request(:get, /api\.open-meteo\.com/)
      .to_return(status: 200, body: weather_payload, headers: { "Content-Type" => "application/json" })
  end

  it "renders the search form on the root path" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Get forecast")
  end

  it "renders the forecast and flags it Live, then Cached on repeat" do
    get root_path, params: { address: "350 Fifth Ave, New York, NY" }
    expect(response.body).to include("70°F")
    expect(response.body).to include("Live")

    get root_path, params: { address: "350 Fifth Ave, New York, NY" }
    expect(response.body).to include("Cached")
  end

  it "shows a friendly error for an unresolvable address" do
    get root_path, params: { address: "this place does not exist 99999" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("find that location")
  end

  it "renders Portuguese labels and Celsius when locale is pt-BR" do
    celsius_payload = {
      "current" => { "time" => "2026-06-15T12:00", "temperature_2m" => 21.3 },
      "current_units" => { "temperature_2m" => "°C" },
      "daily" => {
        "time" => [ "2026-06-15" ],
        "temperature_2m_max" => [ 24.0 ],
        "temperature_2m_min" => [ 18.0 ]
      }
    }.to_json
    stub_request(:get, /api\.open-meteo\.com/)
      .with(query: hash_including("temperature_unit" => "celsius"))
      .to_return(status: 200, body: celsius_payload, headers: { "Content-Type" => "application/json" })

    get root_path, params: { address: "350 Fifth Ave, New York, NY", locale: "pt-BR" }

    expect(response.body).to include("Buscar previsão")
    expect(response.body).to include("21°C")
  end
end
