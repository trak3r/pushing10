class Plane < ApplicationRecord
  belongs_to :player
  belongs_to :current_airport, class_name: "Airport"

  has_many :passengers, dependent: :nullify
  has_many :flights, dependent: :destroy

  def active_flight
    flights.in_progress.first
  end

  def in_flight?
    active_flight.present?
  end

  def boarded_passengers
    passengers.where(delivered: false)
  end

  def status_text
    if in_flight?
      "IN FLIGHT"
    else
      "LANDED"
    end
  end

  def status_airport_code
    if in_flight?
      active_flight.to_airport.code
    else
      current_airport.code
    end
  end

  def fuel_cost(distance)
    rate = plane_type == "light" ? 0.5 : 0.75
    (distance * rate).round
  end

  def status_direction
    if in_flight?
      "#{current_airport.code} \u2192 #{active_flight.to_airport.code}"
    else
      current_airport.code
    end
  end
end
