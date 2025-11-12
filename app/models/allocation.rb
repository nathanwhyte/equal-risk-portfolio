class Allocation < ApplicationRecord
  belongs_to :portfolio

  validates :name, presence: true, uniqueness: { scope: :portfolio_id, case_sensitive: true, message: "already exists for this portfolio" }
  validates :percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :enabled, inclusion: { in: [ true, false ] }
end
