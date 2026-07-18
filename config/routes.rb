Rails.application.routes.draw do
  root "game#planes"

  get "favicon.ico", to: redirect("/icon.svg")

  get "planes/:id", to: "game#plane", as: :plane
  get "airline", to: "game#airline", as: :airline

  post "fly", to: "game#do_fly"
  post "passengers/:id/board", to: "game#board", as: :board_passenger
  post "passengers/:id/unboard", to: "game#unboard", as: :unboard_passenger

  get "up" => "rails/health#show", as: :rails_health_check
end
