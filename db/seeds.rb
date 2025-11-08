# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  # User.create! email_address: "nate@admin.com", password: "unix", password_confirmation: "unix"

  portfolio = Portfolio.find_or_create_by!(name: "Tech Leaders") do |p|
    p.tickers = [
      { symbol: "AAPL", name: "Apple Inc." },
      { symbol: "MSFT", name: "Microsoft Corporation" },
      { symbol: "GOOGL", name: "Alphabet Inc." }
    ]
    p.weights = {
      "AAPL" => 33.3,
      "MSFT" => 33.3,
      "GOOGL" => 33.4
    }
    p.allocations = {
      "Bonds" => {
        "weight" => 5.0,
        "enabled" => false
      }
    }
  end
  portfolio.create_initial_version unless portfolio.portfolio_versions.any?

  portfolio = Portfolio.find_or_create_by!(name: "Diversified Blue Chips") do |p|
    p.tickers = [
      { symbol: "JPM", name: "JPMorgan Chase & Co." },
      { symbol: "JNJ", name: "Johnson & Johnson" },
      { symbol: "PG", name: "The Procter & Gamble Company" },
      { symbol: "XOM", name: "Exxon Mobil Corporation" }
    ]
    p.weights = {
      "JPM" => 25.0,
      "JNJ" => 25.0,
      "PG" => 25.0,
      "XOM" => 25.0
    }
    p.allocations = {
      "Bonds" => {
        "weight" => 20.0,
        "enabled" => true
      }
    }
  end
  portfolio.create_initial_version unless portfolio.portfolio_versions.any?

  portfolio = Portfolio.find_or_create_by!(name: "Growth Stocks") do |p|
    p.tickers = [
      { symbol: "AMZN", name: "Amazon.com Inc." },
      { symbol: "TSLA", name: "Tesla, Inc." },
      { symbol: "NVDA", name: "NVIDIA Corporation" }
    ]
    p.weights = {
      "AMZN" => 33.3,
      "TSLA" => 33.3,
      "NVDA" => 33.4
    }
  end
  portfolio.create_initial_version unless portfolio.portfolio_versions.any?
end
