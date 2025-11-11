class CapAndRedistributeOption < ApplicationRecord
  belongs_to :portfolio

  validates :cap_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: false
  validates :top_n, numericality: { only_integer: true, greater_than: 0 }, allow_nil: false

  # Scope to find active options
  scope :active, -> { where(active: true) }

  # Mark this option as active and deactivate all others for the same portfolio
  def activate!
    portfolio.cap_and_redistribute_options.where.not(id: id).update_all(active: false)
    update!(active: true)
  end

  # Get weight for a specific ticker symbol
  def weight_for(ticker_symbol)
    weights[ticker_symbol.to_s]
  end

  # Check if weights are present
  def has_weights?
    weights.present? && weights.any?
  end
end
