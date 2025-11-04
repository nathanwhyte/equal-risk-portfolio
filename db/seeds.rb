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
      "AAPL" => 0.333,
      "MSFT" => 0.333,
      "GOOGL" => 0.334
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
      "JPM" => 0.25,
      "JNJ" => 0.25,
      "PG" => 0.25,
      "XOM" => 0.25
    }
  end

  Portfolio.find_or_create_by!(name: "Growth Stocks") do |portfolio|
    portfolio.tickers = [
      { symbol: "AMZN", name: "Amazon.com Inc." },
      { symbol: "TSLA", name: "Tesla, Inc." },
      { symbol: "NVDA", name: "NVIDIA Corporation" }
    ]
    portfolio.weights = {
      "AMZN" => 0.333,
      "TSLA" => 0.333,
      "NVDA" => 0.334
    }
  end
end
