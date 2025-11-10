class PortfolioVersion < ApplicationRecord
  belongs_to :portfolio

  # Validations
  validates :tickers, presence: true
  validates :weights, presence: true
  validates :version_number, presence: true, uniqueness: { scope: :portfolio_id }

  # Scopes
  scope :latest, -> { order(created_at: :desc).first }
  scope :by_version, ->(num) { where(version_number: num) }
  scope :chronological, -> { order(version_number: :desc) }

  # Instance methods
  def ticker_symbols
    tickers.map { |t| t["symbol"] || t[:symbol] }
  end

  def weight_for(ticker_symbol)
    weights[ticker_symbol.to_s]
  end
end
