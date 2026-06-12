class Flight < ApplicationRecord
  TIME_SCALE = 120

  belongs_to :plane
  belongs_to :from_airport, class_name: "Airport"
  belongs_to :to_airport, class_name: "Airport"

  scope :in_progress, -> { where(completed_at: nil).where.not(departed_at: nil) }
  scope :arrived, -> { where.not(completed_at: nil) }

  def duration_seconds
    return 0 unless plane
    (distance.to_f / plane.speed * 3600 / TIME_SCALE).round
  end

  def eta
    departed_at + duration_seconds.seconds
  end

  def arrived?
    completed_at.present?
  end

  def in_progress?
    departed_at.present? && completed_at.nil?
  end

  def seconds_remaining
    return 0 if completed_at.present? || departed_at.nil?
    [eta - Time.current, 0].max.to_i
  end
end
