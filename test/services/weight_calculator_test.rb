require "test_helper"

class WeightCalculatorTest < ActiveSupport::TestCase
  def test_returns_original_weights_when_no_allocations_present
    weights = { "AAPL" => 0.5, "MSFT" => 0.5 }

    calculator = WeightCalculator.new(weights: weights, allocations: nil)
    adjusted = calculator.adjusted_weights

    assert_equal weights, adjusted
    refute_same weights, adjusted
  end

  def test_applies_enabled_allocations
    weights = { "AAPL" => 0.5, "MSFT" => 0.5 }
    # Use array format with percentage key (backward compatibility format)
    allocations = [
      { "percentage" => 20.0, "enabled" => true }
    ]

    calculator = WeightCalculator.new(weights: weights, allocations: allocations)
    adjusted = calculator.adjusted_weights

    assert_in_delta 0.4, adjusted["AAPL"], 1e-9
    assert_in_delta 0.4, adjusted["MSFT"], 1e-9
  end

  def test_ignores_disabled_allocations
    weights = { "AAPL" => 0.5 }
    # Use array format with percentage key (backward compatibility format)
    allocations = [
      { "percentage" => 20.0, "enabled" => false }
    ]

    calculator = WeightCalculator.new(weights: weights, allocations: allocations)
    adjusted = calculator.adjusted_weights

    assert_in_delta 0.5, adjusted["AAPL"], 1e-9
  end

  def test_prevents_negative_adjustments
    weights = { "AAPL" => 0.5 }
    # Use array format with percentage key (backward compatibility format)
    # 120% allocation should result in 0.0 adjustment factor
    allocations = [
      { "percentage" => 120.0, "enabled" => true }
    ]

    calculator = WeightCalculator.new(weights: weights, allocations: allocations)
    adjusted = calculator.adjusted_weights

    assert_equal 0.0, adjusted["AAPL"]
  end
end

class WeightCalculatorNewTest < ActiveSupport::TestCase
  test "returns original weights when no allocations present" do
    weights = { "AAPL" => 0.5, "MSFT" => 0.5 }

    calculator = WeightCalculator.new(weights: weights, allocations: [])
    adjusted = calculator.adjusted_weights

    assert_equal weights, adjusted
    refute_same weights, adjusted
  end

  test "applies enabled allocations using Allocation model" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )
    weights = { "AAPL" => 0.5, "MSFT" => 0.5 }
    allocation = portfolio.allocations.create!(
      name: "Cash",
      percentage: 20.0,
      enabled: true
    )

    calculator = WeightCalculator.new(weights: weights, allocations: portfolio.allocations)
    adjusted = calculator.adjusted_weights

    # 20% allocation means 80% remains, so 0.5 * 0.8 = 0.4
    assert_in_delta 0.4, adjusted["AAPL"], 1e-9
    assert_in_delta 0.4, adjusted["MSFT"], 1e-9
  end

  test "ignores disabled allocations" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )
    weights = { "AAPL" => 0.5 }
    allocation = portfolio.allocations.create!(
      name: "Cash",
      percentage: 20.0,
      enabled: false
    )

    calculator = WeightCalculator.new(weights: weights, allocations: portfolio.allocations)
    adjusted = calculator.adjusted_weights

    # Disabled allocation should not affect weights
    assert_in_delta 0.5, adjusted["AAPL"], 1e-9
  end

  test "prevents negative adjustments when allocations exceed 100%" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )
    weights = { "AAPL" => 0.5 }
    # Create multiple allocations that total > 100% to test the negative prevention
    portfolio.allocations.create!(
      name: "Cash",
      percentage: 60.0,
      enabled: true
    )
    portfolio.allocations.create!(
      name: "Bonds",
      percentage: 50.0,
      enabled: true
    )

    calculator = WeightCalculator.new(weights: weights, allocations: portfolio.allocations)
    adjusted = calculator.adjusted_weights

    # Should not go negative, minimum is 0.0 (110% total allocation means -10% remaining, clamped to 0)
    assert_equal 0.0, adjusted["AAPL"]
  end

  test "handles multiple enabled allocations" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )
    weights = { "AAPL" => 0.5, "MSFT" => 0.5 }
    portfolio.allocations.create!(
      name: "Cash",
      percentage: 20.0,
      enabled: true
    )
    portfolio.allocations.create!(
      name: "Bonds",
      percentage: 30.0,
      enabled: true
    )

    calculator = WeightCalculator.new(weights: weights, allocations: portfolio.allocations)
    adjusted = calculator.adjusted_weights

    # 50% total allocation means 50% remains, so 0.5 * 0.5 = 0.25
    assert_in_delta 0.25, adjusted["AAPL"], 1e-9
    assert_in_delta 0.25, adjusted["MSFT"], 1e-9
  end

  test "handles mix of enabled and disabled allocations" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )
    weights = { "AAPL" => 0.5, "MSFT" => 0.5 }
    portfolio.allocations.create!(
      name: "Cash",
      percentage: 20.0,
      enabled: true
    )
    portfolio.allocations.create!(
      name: "Bonds",
      percentage: 30.0,
      enabled: false
    )

    calculator = WeightCalculator.new(weights: weights, allocations: portfolio.allocations)
    adjusted = calculator.adjusted_weights

    # Only 20% allocation (disabled one ignored), so 80% remains, so 0.5 * 0.8 = 0.4
    assert_in_delta 0.4, adjusted["AAPL"], 1e-9
    assert_in_delta 0.4, adjusted["MSFT"], 1e-9
  end
end
