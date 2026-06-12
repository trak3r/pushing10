class Airport < ApplicationRecord
  has_many :planes, foreign_key: :current_airport_id, dependent: :nullify
  has_many :origin_passengers, class_name: "Passenger", foreign_key: :origin_airport_id, dependent: :destroy
  has_many :destination_passengers, class_name: "Passenger", foreign_key: :destination_airport_id, dependent: :destroy
  has_many :departing_flights, class_name: "Flight", foreign_key: :from_airport_id, dependent: :destroy
  has_many :arriving_flights, class_name: "Flight", foreign_key: :to_airport_id, dependent: :destroy

  def distance_to(other)
    d_lat = (other.latitude - latitude) * Math::PI / 180
    d_lon = (other.longitude - longitude) * Math::PI / 180
    a = Math.sin(d_lat / 2) ** 2 +
        Math.cos(latitude * Math::PI / 180) * Math.cos(other.latitude * Math::PI / 180) *
        Math.sin(d_lon / 2) ** 2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    (6371 * c).round
  end

  def available_passengers
    origin_passengers.where(player: nil, plane: nil, delivered: false)
  end
end
