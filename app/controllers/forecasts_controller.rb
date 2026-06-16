# frozen_string_literal: true

class ForecastsController < ApplicationController
  def show
    @address = params[:address].to_s.strip
    return if @address.empty?

    @result = Weather::ForecastService.new(unit: t("weather.unit")).call(@address)
  rescue Weather::AddressNotFound
    @error = t("forecasts.errors.not_found")
  rescue Weather::ForecastUnavailable => e
    Rails.logger.warn("[Forecast] #{e.class}: #{e.message}")
    @error = t("forecasts.errors.unavailable")
  end
end
