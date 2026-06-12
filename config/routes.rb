Rails.application.routes.draw do
  root "game#dashboard"

  post "fly", to: "game#do_fly"
  post "passengers/:id/board", to: "game#board", as: :board_passenger
  post "passengers/:id/unboard", to: "game#unboard", as: :unboard_passenger

  get "up" => "rails/health#show", as: :rails_health_check
end
