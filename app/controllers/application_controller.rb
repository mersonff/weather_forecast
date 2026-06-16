class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  around_action :switch_locale

  private

  def switch_locale(&action)
    I18n.with_locale(locale_from_params || locale_from_header, &action)
  end

  def locale_from_params
    locale = params[:locale].to_s.to_sym
    locale if I18n.available_locales.include?(locale)
  end

  def locale_from_header
    request.env["HTTP_ACCEPT_LANGUAGE"].to_s.scan(/[a-z]{2}(?:-[A-Z]{2})?/i)
      .map { |tag| tag.sub(/-(\w+)/) { "-#{$1.upcase}" }.to_sym }
      .find { |tag| I18n.available_locales.include?(tag) } || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
