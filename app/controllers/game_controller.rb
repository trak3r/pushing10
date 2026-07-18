class GameController < ApplicationController
  before_action :load_player

  def planes
    @planes = @player.planes.includes(:current_airport, :passengers, :flights)
    process_arrivals
  end

  def plane
    @plane = @player.planes.includes(:current_airport, :passengers, :flights).find(params[:id])
    process_arrivals

    @current_airport = @plane.current_airport.reload
    @active_flight = @plane.active_flight

    if @active_flight
      @seconds_remaining = @active_flight.seconds_remaining
    end

    @airport_passengers = build_passenger_list
    @boarded_passengers = @plane.boarded_passengers
    @plane_full = @plane.capacity > 0 && @boarded_passengers.count >= @plane.capacity
    @destinations = build_destinations
  end

  def map
    @airports = Airport.all
    process_arrivals
    @active_flights = Flight.in_progress.includes(:plane, :from_airport, :to_airport)

    lats = @airports.map(&:latitude)
    lngs = @airports.map(&:longitude)
    @map_pad = 0.5
    @min_lat = lats.min - @map_pad
    @max_lat = lats.max + @map_pad
    @min_lng = lngs.min - @map_pad
    @max_lng = lngs.max + @map_pad
    @map_w = 440
    @map_h = 520
  end

  def airline
    @planes = @player.planes.includes(:current_airport, :passengers)
    process_arrivals
    @total_flights = Flight.where(plane: @planes).count
    @completed_flights = Flight.where(plane: @planes).arrived.count
    @total_revenue = Flight.where(plane: @planes).arrived.sum(:revenue)
    @total_fuel = Flight.where(plane: @planes).arrived.sum(:fuel_cost)
    @total_passengers_delivered = Passenger.where(player: @player, delivered: true).count
    @in_air_count = @planes.count(&:in_flight?)
  end

  def board
    plane = @player.planes.find(params[:plane_id] || params[:id])
    if plane.in_flight?
      redirect_to plane_path(plane), alert: "Can't board while in flight!"
      return
    end

    passenger = Passenger.find(params[:id])

    if passenger.origin_airport != plane.current_airport
      redirect_to plane_path(plane), alert: "That passenger isn't at this airport!"
      return
    end

    if passenger.player.present? || passenger.plane.present?
      redirect_to plane_path(plane), alert: "That passenger is already taken!"
      return
    end

    boarded_count = plane.boarded_passengers.count
    if boarded_count >= plane.capacity
      redirect_to plane_path(plane), alert: "Plane is full! Capacity: #{plane.capacity}"
      return
    end

    passenger.update!(player: @player, plane: plane)
    Turbo::StreamsChannel.broadcast_refresh_to("game")
    redirect_to plane_path(plane), notice: "#{passenger.name} boarded!"
  end

  def unboard
    plane = @player.planes.find(params[:plane_id] || params[:id])
    if plane.in_flight?
      redirect_to plane_path(plane), alert: "Can't unboard while in flight!"
      return
    end

    passenger = Passenger.find(params[:id])

    if passenger.plane != plane
      redirect_to plane_path(plane), alert: "That passenger isn't on your plane!"
      return
    end

    passenger.update!(player: nil, plane: nil)
    Turbo::StreamsChannel.broadcast_refresh_to("game")
    redirect_to plane_path(plane), notice: "#{passenger.name} deplaned!"
  end

  def do_fly
    plane = @player.planes.find(params[:plane_id] || params[:id])

    if plane.in_flight?
      redirect_to plane_path(plane), alert: "Plane is already in flight!"
      return
    end

    destination = Airport.find(params[:destination_id])
    distance = plane.current_airport.distance_to(destination)

    if distance > plane.range
      redirect_to plane_path(plane), alert: "Destination out of range! (#{distance}km > #{plane.range}km)"
      return
    end

    fuel_cost = plane.fuel_cost(distance)
    prepaid = plane.boarded_passengers.select { |p| p.destination_airport_id == destination.id }.sum(&:reward)

    if @player.coins + prepaid < fuel_cost
      needed = fuel_cost - prepaid
      redirect_to plane_path(plane), alert: "Not enough coins for fuel! Need #{fuel_cost}, have #{@player.coins} (+#{prepaid} prepaid). Need #{needed} more."
      return
    end

    @player.decrement!(:coins, fuel_cost)

    Flight.create!(
      plane: plane,
      from_airport: plane.current_airport,
      to_airport: destination,
      distance: distance,
      fuel_cost: fuel_cost,
      revenue: 0,
      departed_at: Time.current
    )

    Turbo::StreamsChannel.broadcast_refresh_to("game")
    redirect_to plane_path(plane), notice: "Departed for #{destination.code}!"
  end

  helper_method :map_x, :map_y, :arc_path, :arc_point, :flight_progress

  def map_x(lng)
    (lng - @min_lng) / (@max_lng - @min_lng) * @map_w + 20
  end

  def map_y(lat)
    (@max_lat - lat) / (@max_lat - @min_lat) * @map_h + 20
  end

  def arc_path(from_lat, from_lng, to_lat, to_lng)
    x1 = map_x(from_lng)
    y1 = map_y(from_lat)
    x2 = map_x(to_lng)
    y2 = map_y(to_lat)

    mx = (x1 + x2) / 2.0
    my = (y1 + y2) / 2.0
    dx = x2 - x1
    dy = y2 - y1
    dist = Math.sqrt(dx * dx + dy * dy)
    nx = -dy / dist
    ny = dx / dist
    arc_height = dist * 0.4

    cx = mx + nx * arc_height
    cy = my + ny * arc_height

    "M #{x1.round(1)} #{y1.round(1)} Q #{cx.round(1)} #{cy.round(1)} #{x2.round(1)} #{y2.round(1)}"
  end

  def arc_point(from_lat, from_lng, to_lat, to_lng, t)
    x1 = map_x(from_lng)
    y1 = map_y(from_lat)
    x2 = map_x(to_lng)
    y2 = map_y(to_lat)

    mx = (x1 + x2) / 2.0
    my = (y1 + y2) / 2.0
    dx = x2 - x1
    dy = y2 - y1
    dist = Math.sqrt(dx * dx + dy * dy)
    nx = -dy / dist
    ny = dx / dist
    arc_height = dist * 0.4

    cx = mx + nx * arc_height
    cy = my + ny * arc_height

    t_clamped = [[t, 0].max, 1].min
    u = 1 - t_clamped
    x = u * u * x1 + 2 * u * t_clamped * cx + t_clamped * t_clamped * x2
    y = u * u * y1 + 2 * u * t_clamped * cy + t_clamped * t_clamped * y2

    tx = 2 * u * (cx - x1) + 2 * t_clamped * (x2 - cx)
    ty = 2 * u * (cy - y1) + 2 * t_clamped * (y2 - cy)
    angle = Math.atan2(ty, tx) * 180 / Math::PI

    { x: x.round(1), y: y.round(1), angle: angle.round(1) }
  end

  def flight_progress(flight)
    return 0 unless flight.in_progress?
    elapsed = Time.current - flight.departed_at
    total = flight.duration_seconds
    [elapsed / total, 1.0].min
  end

  private

  def process_arrivals
    arrived = false
    @player.planes.each do |plane|
      flight = plane.active_flight
      next unless flight
      next if Time.current < flight.eta

      arrived = true

      boarded = plane.boarded_passengers
      revenue = 0

      boarded.each do |passenger|
        if passenger.destination_airport == flight.to_airport
          revenue += passenger.reward
          passenger.update!(delivered: true)
        end
      end

      flight.update!(revenue: revenue, completed_at: Time.current)
      plane.update!(current_airport: flight.to_airport)
      @player.increment!(:coins, revenue)

      replenish_passengers(flight.to_airport)
    end

    Turbo::StreamsChannel.broadcast_refresh_to("game") if arrived
  end

  def replenish_passengers(airport)
    names = %w[Alice Bob Charlie Dana Eve Frank Grace Henry Ivy Jack Kate Liam Mia Noah Olivia Paul Quinn Rose Sam Tessa Uma]
    dests = Airport.where.not(id: airport.id).to_a
    rand(1..2).times do
      dest = dests.sample
      dist = airport.distance_to(dest)
      Passenger.create!(
        name: names.sample,
        origin_airport: airport,
        destination_airport: dest,
        reward: (dist * 0.5 + rand(10..30)).to_i
      )
    end
  end

  def build_passenger_list
    airport_pax = @current_airport.origin_passengers.where(delivered: false)
    onboard_pax = @plane.boarded_passengers.where.not(origin_airport: @current_airport)

    (airport_pax + onboard_pax).uniq.map do |p|
      status = if p.plane_id == @plane.id
        :boarded
      elsif p.plane_id.present?
        :taken
      else
        :available
      end
      { passenger: p, status: status }
    end
  end

  def build_destinations
    boarded = @plane.boarded_passengers
    Airport.where.not(id: @current_airport.id).map do |dest|
      dist = @current_airport.distance_to(dest)
      fuel = @plane.fuel_cost(dist)
      pax_revenue = boarded.select { |p| p.destination_airport_id == dest.id }.sum(&:reward)
      {
        airport: dest,
        distance: dist,
        in_range: dist <= @plane.range,
        fuel_cost: fuel,
        pax_revenue: pax_revenue,
        net: pax_revenue - fuel,
        deliverable_count: boarded.count { |p| p.destination_airport_id == dest.id }
      }
    end.sort_by { |d| [d[:deliverable_count] > 0 ? 0 : 1, -d[:net]] }
  end

  def load_player
    @player = Player.first
  end
end