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
  User.find_or_create_by!(email_address: "nate@admin.com") do |u|
    u.password = "unix"
    u.password_confirmation = "unix"
  end

  Portfolio.find_or_create_by!(name: "Tech Leaders") do |p|
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
  end

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
  end
  portfolio.allocations.create!(name: "Bonds", percentage: 20.0, enabled: false) if portfolio.allocations.empty?
  portfolio.cap_and_redistribute_options.create!(active: false, cap_percentage: 0.23, top_n: 3, weights: {
    "JPM" => 23.03,
    "JNJ" => 23.0,
    "PG" => 27.14,
    "XOM" => 26.83
  }) if portfolio.cap_and_redistribute_options.empty?

  Portfolio.find_or_create_by!(name: "Growth Stocks") do |p|
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

  # Create a copy of Tech Leaders portfolio
  tech_leaders = Portfolio.find_by(name: "Tech Leaders")
  if tech_leaders
    Portfolio.find_or_create_by!(name: "Tech Leaders Copy") do |p|
      p.copy_of = tech_leaders
      p.tickers = tech_leaders.tickers
      p.weights = tech_leaders.weights
    end
  end
end
