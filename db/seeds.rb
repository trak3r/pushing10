require "securerandom"

def distance_km(lat1, lon1, lat2, lon2)
  d_lat = (lat2 - lat1) * Math::PI / 180
  d_lon = (lon2 - lon1) * Math::PI / 180
  a = Math.sin(d_lat / 2) ** 2 +
      Math.cos(lat1 * Math::PI / 180) * Math.cos(lat2 * Math::PI / 180) *
      Math.sin(d_lon / 2) ** 2
  c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  6371 * c
end

puts "Creating player..."
player = Player.create!(name: "Pilot", coins: 1000)

puts "Creating airports..."
airports_data = [
  { name: "London Heathrow",    code: "LHR", latitude: 51.4700, longitude: -0.4543 },
  { name: "Manchester",         code: "MAN", latitude: 53.4808, longitude: -2.2426 },
  { name: "Edinburgh",          code: "EDI", latitude: 55.9500, longitude: -3.3725 },
  { name: "Dublin",             code: "DUB", latitude: 53.4213, longitude: -6.2700 },
  { name: "Paris Charles de Gaulle", code: "CDG", latitude: 49.0097, longitude: 2.5478 },
]

airports = airports_data.map { |a| Airport.create!(a) }

puts "Creating starter planes..."
plane1 = Plane.create!(
  player: player,
  name: "Skyhopper",
  plane_type: "light",
  speed: 250,
  range: 400,
  capacity: 2,
  current_airport: airports[0]
)

plane2 = Plane.create!(
  player: player,
  name: "Airvan",
  plane_type: "regional",
  speed: 300,
  range: 600,
  capacity: 4,
  current_airport: airports[1]
)

puts "Generating passengers..."
passenger_names = %w[
  Alice Bob Charlie Dana Eve Frank Grace Henry Ivy Jack
  Kate Liam Mia Noah Olivia Paul Quinn Rose Sam Tessa Uma
]

airports.each do |origin|
  dests = airports.select { |a| a != origin }
  3.times do
    dest = dests.sample
    distance = distance_km(origin.latitude, origin.longitude, dest.latitude, dest.longitude)
    reward = (distance * 0.5 + rand(10..30)).to_i

    Passenger.create!(
      name: passenger_names.sample,
      origin_airport: origin,
      destination_airport: dest,
      reward: reward
    )
  end
end

puts "Done! Created #{Airport.count} airports, #{Passenger.count} passengers."
puts "Player #{player.name} has #{player.coins} coins."
player.planes.each { |p| puts "  #{p.name} at #{p.current_airport.code}" }
