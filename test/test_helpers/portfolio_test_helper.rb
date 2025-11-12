module PortfolioTestHelper
  # Creates a basic portfolio with common defaults for testing
  # Returns the created portfolio
  def create_test_portfolio(name: "Test Portfolio", tickers: nil, weights: nil)
    tickers ||= [ { symbol: "AAPL", name: "Apple" } ]
    weights ||= { "AAPL" => 1.0 }

    Portfolio.create!(
      name: name,
      tickers: tickers,
      weights: weights
    )
  end

  # Creates a portfolio with allocations for testing
  # Returns the created portfolio
  def create_portfolio_with_allocations(allocations: [], **portfolio_options)
    portfolio = create_test_portfolio(**portfolio_options)

    allocations.each do |allocation_data|
      portfolio.allocations.create!(allocation_data)
    end

    portfolio
  end
end
