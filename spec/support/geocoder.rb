# frozen_string_literal: true

Geocoder.configure(lookup: :test)

RSpec.configure do |config|
  config.before do
    Geocoder::Lookup::Test.reset
    Geocoder::Lookup::Test.set_default_stub([])
  end
end
