class Passenger < ApplicationRecord
  belongs_to :origin_airport, class_name: "Airport"
  belongs_to :destination_airport, class_name: "Airport"
  belongs_to :player, optional: true
  belongs_to :plane, optional: true
end
