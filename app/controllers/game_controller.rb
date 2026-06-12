class GameController < ApplicationController
  before_action :load_player

  def dashboard
    @plane = @player.planes.first
    @current_airport = @plane.current_airport
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
    destination = Airport.find(params[:destination_id])
    distance = plane.current_airport.distance_to(destination)

    if distance > plane.range
      redirect_to root_path, alert: "Destination out of range! (#{distance}km > #{plane.range}km)"
      return
    end

    boarded = plane.passengers.where(delivered: false)
    revenue = 0

    boarded.each do |passenger|
      if passenger.destination_airport == destination
        revenue += passenger.reward
        passenger.update!(delivered: true)
      end
    end

    Flight.create!(
      plane: plane,
      from_airport: plane.current_airport,
      to_airport: destination,
      distance: distance,
      revenue: revenue,
      completed_at: Time.current
    )

    plane.update!(current_airport: destination)
    @player.increment!(:coins, revenue)

    passengers_delivered = revenue > 0 ? boarded.select { |p| p.destination_airport == destination }.count : 0
    redirect_to root_path, notice: "Flew to #{destination.code}! #{passengers_delivered} passengers delivered, earned #{revenue} coins."
  end

  private

  def load_player
    @player = Player.first
  end
end
