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

    if @player.coins < fuel_cost
      redirect_to plane_path(plane), alert: "Not enough coins for fuel! Need #{fuel_cost}, have #{@player.coins}."
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

    redirect_to plane_path(plane), notice: "Departed for #{destination.code}!"
  end

  private

  def process_arrivals
    @player.planes.each do |plane|
      flight = plane.active_flight
      next unless flight
      next if Time.current < flight.eta

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