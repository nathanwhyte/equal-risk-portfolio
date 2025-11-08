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
    allocations = {
      "Cash" => { "weight" => 20.0, "enabled" => true }
    }

    calculator = WeightCalculator.new(weights: weights, allocations: allocations)
    adjusted = calculator.adjusted_weights

    assert_in_delta 0.4, adjusted["AAPL"], 1e-9
    assert_in_delta 0.4, adjusted["MSFT"], 1e-9
  end

  def test_ignores_disabled_allocations
    weights = { "AAPL" => 0.5 }
    allocations = {
      "Cash" => { "weight" => 20.0, "enabled" => false }
    }

    calculator = WeightCalculator.new(weights: weights, allocations: allocations)
    adjusted = calculator.adjusted_weights

    assert_in_delta 0.5, adjusted["AAPL"], 1e-9
  end

  def test_prevents_negative_adjustments
    weights = { "AAPL" => 0.5 }
    allocations = {
      "Cash" => { "weight" => 120.0, "enabled" => true }
    }

    calculator = WeightCalculator.new(weights: weights, allocations: allocations)
    adjusted = calculator.adjusted_weights

    assert_equal 0.0, adjusted["AAPL"]
  end
end
