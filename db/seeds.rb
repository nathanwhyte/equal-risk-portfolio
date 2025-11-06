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
  User.create! email_address: "nate@admin.com", password: "unix", password_confirmation: "unix"

  Portfolio.find_or_create_by!(name: "Tech Leaders") do |portfolio|
    portfolio.tickers = [
      { symbol: "AAPL", name: "Apple Inc." },
      { symbol: "MSFT", name: "Microsoft Corporation" },
      { symbol: "GOOGL", name: "Alphabet Inc." }
    ]
    portfolio.weights = {
      "AAPL" => 33.3,
      "MSFT" => 33.3,
      "GOOGL" => 33.4
    }
    portfolio.allocations = {
      "Bonds" => {
        "weight" => 5.0,
        "enabled" => false
      }
    }
  end

  Portfolio.find_or_create_by!(name: "Diversified Blue Chips") do |portfolio|
    portfolio.tickers = [
      { symbol: "JPM", name: "JPMorgan Chase & Co." },
      { symbol: "JNJ", name: "Johnson & Johnson" },
      { symbol: "PG", name: "The Procter & Gamble Company" },
      { symbol: "XOM", name: "Exxon Mobil Corporation" }
    ]
    portfolio.weights = {
      "JPM" => 25.0,
      "JNJ" => 25.0,
      "PG" => 25.0,
      "XOM" => 25.0
    }
    portfolio.allocations = {
      "Bonds" => {
        "weight" => 20.0,
        "enabled" => true
      }
    }
  end

  Portfolio.find_or_create_by!(name: "Growth Stocks") do |portfolio|
    portfolio.tickers = [
      { symbol: "AMZN", name: "Amazon.com Inc." },
      { symbol: "TSLA", name: "Tesla, Inc." },
      { symbol: "NVDA", name: "NVIDIA Corporation" }
    ]
    portfolio.weights = {
      "AMZN" => 33.3,
      "TSLA" => 33.3,
      "NVDA" => 33.4
    }
  end
end
