class GameController < ApplicationController
  before_action :load_player

  def dashboard
    @plane = @player.planes.first

    process_arrivals

    @current_airport = @plane.current_airport
    @active_flight = @plane.active_flight

    if @active_flight
      @flight_eta = @active_flight.eta
      @seconds_remaining = @active_flight.seconds_remaining
    end

    @available_passengers = @current_airport.available_passengers
    @boarded_passengers = @plane.passengers.where(delivered: false)
    @destinations = Airport.where.not(id: @current_airport.id).map do |dest|
      dist = @current_airport.distance_to(dest)
      {
        airport: dest,
        distance: dist,
        in_range: dist <= @plane.range,
        deliverable_passengers: @boarded_passengers.count { |p| p.destination_airport_id == dest.id }
      }
    end.sort_by { |d| d[:distance] }
  end

  def board
    if @player.planes.first.in_flight?
      redirect_to root_path, alert: "Can't board while in flight!"
      return
    end

    passenger = Passenger.find(params[:id])
    plane = @player.planes.first

    if passenger.origin_airport != plane.current_airport
      redirect_to root_path, alert: "That passenger isn't at this airport!"
      return
    end

    if passenger.player.present? || passenger.plane.present?
      redirect_to root_path, alert: "That passenger is already taken!"
      return
    end

    boarded_count = plane.passengers.where(delivered: false).count
    if boarded_count >= plane.capacity
      redirect_to root_path, alert: "Plane is full! Capacity: #{plane.capacity}"
      return
    end

    passenger.update!(player: @player, plane: plane)
    redirect_to root_path, notice: "#{passenger.name} boarded!"
  end

  def unboard
    if @player.planes.first.in_flight?
      redirect_to root_path, alert: "Can't unboard while in flight!"
      return
    end

    passenger = Passenger.find(params[:id])
    plane = @player.planes.first

    if passenger.plane != plane
      redirect_to root_path, alert: "That passenger isn't on your plane!"
      return
    end

    passenger.update!(player: nil, plane: nil)
    redirect_to root_path, notice: "#{passenger.name} removed from plane."
  end

  def do_fly
    plane = @player.planes.first

    if plane.in_flight?
      redirect_to root_path, alert: "Plane is already in flight!"
      return
    end

    destination = Airport.find(params[:destination_id])
    distance = plane.current_airport.distance_to(destination)

    if distance > plane.range
      redirect_to root_path, alert: "Destination out of range! (#{distance}km > #{plane.range}km)"
      return
    end

    boarded = plane.passengers.where(delivered: false)
    if boarded.empty?
      redirect_to root_path, alert: "No passengers on board! Board some passengers first."
      return
    end

    flight = Flight.create!(
      plane: plane,
      from_airport: plane.current_airport,
      to_airport: destination,
      distance: distance,
      revenue: 0,
      departed_at: Time.current
    )

    duration = flight.duration_seconds
    redirect_to root_path, notice: "Departed for #{destination.code}! ETA #{duration} seconds."
  end

  private

  def process_arrivals
    plane = @player.planes.first
    flight = plane.active_flight
    return unless flight
    return if Time.current < flight.eta

    boarded = plane.passengers.where(delivered: false)
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
    flash.now[:notice] = "Landed at #{flight.to_airport.code}! #{delivered} passengers delivered, earned #{revenue} coins."
  end

  def load_player
    @player = Player.first
  end
end
