class Player < ApplicationRecord
  has_many :planes, dependent: :destroy
  has_many :passengers, dependent: :nullify
  has_many :flights, through: :planes
end
