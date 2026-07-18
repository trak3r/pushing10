Rails.application.config.turbo.tap do |config|
  config.refresh_method = :morph
  config.refresh_scroll = :preserve
end
