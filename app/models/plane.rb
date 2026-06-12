class Plane < ApplicationRecord
  belongs_to :player
  belongs_to :current_airport, class_name: "Airport"

  has_many :passengers, dependent: :nullify
  has_many :flights, dependent: :destroy
end
