class GameController < ApplicationController
  before_action :load_player

  def dashboard
    @planes = @player.planes.includes(:current_airport, :passengers)
    process_arrivals

    @plane = selected_plane
    @current_airport = @plane.current_airport
    @active_flight = @plane.active_flight

    if @active_flight
      @flight_eta = @active_flight.eta
      @seconds_remaining = @active_flight.seconds_remaining
    end

    @airport_passengers = build_passenger_list
    @boarded_passengers = @plane.boarded_passengers
    @plane_full = @plane.capacity > 0 && @boarded_passengers.count >= @plane.capacity
    @destinations = Airport.where.not(id: @current_airport.id).map do |dest|
      dist = @current_airport.distance_to(dest)
      fuel = @plane.fuel_cost(dist)
      pax_revenue = @boarded_passengers.select { |p| p.destination_airport_id == dest.id }.sum(&:reward)
      {
        airport: dest,
        distance: dist,
        in_range: dist <= @plane.range,
        fuel_cost: fuel,
        pax_revenue: pax_revenue,
        net: pax_revenue - fuel,
        deliverable_count: @boarded_passengers.count { |p| p.destination_airport_id == dest.id }
      }
    end.sort_by { |d| d[:distance] }
  end

  def board
    plane = selected_plane
    if plane.in_flight?
      redirect_to root_path(plane_id: plane.id), alert: "Can't board while in flight!"
      return
    end

    passenger = Passenger.find(params[:id])

    if passenger.origin_airport != plane.current_airport
      redirect_to root_path(plane_id: plane.id), alert: "That passenger isn't at this airport!"
      return
    end

    if passenger.player.present? || passenger.plane.present?
      redirect_to root_path(plane_id: plane.id), alert: "That passenger is already taken!"
      return
    end

    boarded_count = plane.boarded_passengers.count
    if boarded_count >= plane.capacity
      redirect_to root_path(plane_id: plane.id), alert: "Plane is full! Capacity: #{plane.capacity}"
      return
    end

    passenger.update!(player: @player, plane: plane)
    redirect_to root_path(plane_id: plane.id)
  end

  def unboard
    plane = selected_plane
    if plane.in_flight?
      redirect_to root_path(plane_id: plane.id), alert: "Can't unboard while in flight!"
      return
    end

    passenger = Passenger.find(params[:id])

    if passenger.plane != plane
      redirect_to root_path(plane_id: plane.id), alert: "That passenger isn't on your plane!"
      return
    end

    passenger.update!(player: nil, plane: nil)
    redirect_to root_path(plane_id: plane.id)
  end

  def do_fly
    plane = selected_plane

    if plane.in_flight?
      redirect_to root_path(plane_id: plane.id), alert: "Plane is already in flight!"
      return
    end

    destination = Airport.find(params[:destination_id])
    distance = plane.current_airport.distance_to(destination)

    if distance > plane.range
      redirect_to root_path(plane_id: plane.id), alert: "Destination out of range! (#{distance}km > #{plane.range}km)"
      return
    end

    fuel_cost = plane.fuel_cost(distance)

    if @player.coins < fuel_cost
      redirect_to root_path(plane_id: plane.id), alert: "Not enough coins for fuel! Need #{fuel_cost}, have #{@player.coins}."
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

    redirect_to root_path(plane_id: plane.id), notice: "Departed for #{destination.code}!"
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

      delivered = boarded.count { |p| p.destination_airport == flight.to_airport }
      net = revenue - flight.fuel_cost
      flash.now[:notice] = "#{plane.name} landed at #{flight.to_airport.code}! #{delivered} delivered, pax #{revenue}c, fuel #{flight.fuel_cost}c, net #{net}c."
    end
  end

  def selected_plane
    if params[:plane_id]
      @player.planes.find(params[:plane_id])
    else
      @player.planes.first
    end
  end

  def build_passenger_list
    @current_airport.origin_passengers
      .where(delivered: false)
      .includes(:destination_airport)
      .map do |p|
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

  def load_player
    @player = Player.first
  end
end
