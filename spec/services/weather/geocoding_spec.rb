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

  it "raises AddressNotFound when the match has no postal code" do
    Geocoder::Lookup::Test.add_stub(
      "middle of the ocean",
      [ { "latitude" => 0.0, "longitude" => 0.0 } ]
    )

    expect { geocoding.call("middle of the ocean") }
      .to raise_error(Weather::AddressNotFound, /postal code/)
  end
end
