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
    return 0.0 if allocations.blank?

    # Handle both ActiveRecord associations and hash/array inputs
    if allocations.respond_to?(:sum)
      # ActiveRecord association or array
      allocations.sum do |allocation|
        if allocation.is_a?(Allocation)
          allocation.enabled ? (allocation.percentage.to_f / 100.0) : 0
        elsif allocation.is_a?(Hash)
          # Support hash format for backward compatibility
          (allocation[:enabled] || allocation["enabled"]) ? ((allocation[:percentage] || allocation["percentage"]).to_f / 100.0) : 0
        else
          0
        end
      end
    else
      0.0
    end
  end
end
