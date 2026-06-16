# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::Geocoding do
  subject(:geocoding) { described_class.new }

  it "resolves an address into a Location with zip and coordinates" do
    Geocoder::Lookup::Test.add_stub(
      "350 Fifth Ave, New York, NY",
      [ { "latitude" => 40.748, "longitude" => -73.985, "postal_code" => "10118" } ]
    )

    location = geocoding.call("350 Fifth Ave, New York, NY")

    expect(location).to have_attributes(
      address: "350 Fifth Ave, New York, NY",
      zip: "10118",
      latitude: 40.748,
      longitude: -73.985
    )
  end

  it "raises AddressNotFound for a blank address" do
    expect { geocoding.call("   ") }.to raise_error(Weather::AddressNotFound)
  end

  it "raises AddressNotFound when nothing matches" do
    Geocoder::Lookup::Test.add_stub("nowhere at all", [])

    expect { geocoding.call("nowhere at all") }.to raise_error(Weather::AddressNotFound)
  end

  it "returns a Location with a nil zip when the match has no postal code" do
    Geocoder::Lookup::Test.add_stub(
      "São Paulo, São Paulo",
      [ { "latitude" => -23.55, "longitude" => -46.63 } ]
    )

    location = geocoding.call("São Paulo, São Paulo")

    expect(location).to have_attributes(zip: nil, latitude: -23.55, longitude: -46.63)
  end
end
