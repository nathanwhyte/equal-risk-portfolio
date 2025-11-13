class CapAndRedistributeOption < ApplicationRecord
  belongs_to :portfolio

  validates :cap_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: false
  validates :top_n, numericality: { only_integer: true, greater_than: 0 }, allow_nil: false
  validate :weights_must_be_valid_hash

  # Scope to find active options
  scope :active, -> { where(active: true) }

  # Mark this option as active and deactivate all others for the same portfolio
  # Note: Uses update_all to bypass callbacks for performance when deactivating other options
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

  private

  def weights_must_be_valid_hash
    return if weights.nil? || weights.empty?

    unless weights.is_a?(Hash)
      errors.add(:weights, "must be a hash")
      return
    end

    weights.each do |key, value|
      unless value.is_a?(Numeric) && value >= 0
        errors.add(:weights, "all values must be non-negative numbers")
        return
      end
    end

    # Check if weights sum to approximately 100 (with tolerance for floating point)
    total = weights.values.sum
    unless (total - 1.0).abs < 100.0
      errors.add(:weights, "must sum to approximately 1.0 (currently #{total.round(4)})")
    end
  end
end
