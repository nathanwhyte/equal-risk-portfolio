class Allocation < ApplicationRecord
  belongs_to :portfolio

  validates :name, presence: true
  validates :percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :enabled, inclusion: { in: [ true, false ] }
end
