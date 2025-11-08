module PortfolioHelper
  def tickers_from_version(version)
    return [] unless version

    tickers_from_hash(version.tickers)
  end

  def tickers_from_hash(tickers)
    Array(tickers).map do |ticker|
      symbol = ticker["symbol"] || ticker[:symbol]
      name = ticker["name"] || ticker[:name]
      Ticker.new(symbol: symbol, name: name)
    end
  end

  def tickers_to_hash(tickers)
    Array(tickers).map do |ticker|
      { "symbol" => ticker.symbol, "name" => ticker.name }
    end
  end
end
