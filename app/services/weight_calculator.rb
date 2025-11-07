class WeightCalculator
  def initialize(weights:, allocations:)
    @weights = weights || {}
    @allocations = allocations || {}
  end

  def adjusted_weights
    return weights.dup if allocations.blank?

    adjustment_factor = [ 1.0 - enabled_allocation_sum, 0.0 ].max

    weights.each_with_object({}) do |(ticker, weight), adjusted|
      adjusted[ticker] = weight.to_f * adjustment_factor
    end
  end

  private

  attr_reader :weights, :allocations

  def enabled_allocation_sum
    allocations.sum do |_name, allocation_data|
      allocation = normalize_allocation(allocation_data)
      allocation[:enabled] ? (allocation[:weight].to_f / 100.0) : 0
    end
  end

  def normalize_allocation(value)
    if value.is_a?(Hash)
      {
        weight: value["weight"] || value[:weight] || value.to_f,
        enabled: value.key?("enabled") ? value["enabled"] != false : value[:enabled] != false
      }
    else
      {
        weight: value.to_f,
        enabled: true
      }
    end
  end
end
