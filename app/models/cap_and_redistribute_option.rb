class CapAndRedistributeOption < ApplicationRecord
  belongs_to :portfolio

  validates :cap_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: false
  validates :top_n, numericality: { only_integer: true, greater_than: 0 }, allow_nil: false
end
