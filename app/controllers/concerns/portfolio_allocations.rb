module PortfolioAllocations
  extend ActiveSupport::Concern

  private

  def handle_allocations_update
    Portfolio.transaction do
      # Check both top-level and nested params (form_with nests, button_to doesn't)
      toggle_allocation if params[:toggle_allocation].present? || params.dig(:portfolio, :toggle_allocation).present?
      remove_allocation if params[:remove_allocation].present? || params.dig(:portfolio, :remove_allocation).present?

      # For adding, check nested params from form_with
      allocation_name = params.dig(:portfolio, :allocation_name) || params[:allocation_name]
      allocation_weight = params.dig(:portfolio, :allocation_weight) || params[:allocation_weight]
      add_allocation if allocation_name.present? && allocation_weight.present?

      validate_allocation_total

      if @portfolio.errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if @portfolio.errors.empty?
      redirect_to @portfolio, notice: "Allocations were successfully updated."
    else
      Rails.logger.error "Failed to save allocations: #{@portfolio.errors.full_messages.inspect}"
      handle_allocation_failure
    end
  end

  def toggle_allocation
    allocation_id = params[:toggle_allocation] || params.dig(:portfolio, :toggle_allocation)
    allocation = @portfolio.allocations.find_by(id: allocation_id)

    unless allocation
      @portfolio.errors.add(:allocations, "Allocation not found")
      return
    end

    unless allocation.update(enabled: !allocation.enabled)
      @portfolio.errors.add(:allocations, "Failed to update allocation: #{allocation.errors.full_messages.join(', ')}")
    end
  end

  def remove_allocation
    allocation_id = params[:remove_allocation] || params.dig(:portfolio, :remove_allocation)
    allocation = @portfolio.allocations.find_by(id: allocation_id)

    unless allocation
      @portfolio.errors.add(:allocations, "Allocation not found")
      return
    end

    unless allocation.destroy
      @portfolio.errors.add(:allocations, "Failed to remove allocation")
    end
  end

  def add_allocation
    allocation_name = (params.dig(:portfolio, :allocation_name) || params[:allocation_name]).to_s.strip
    allocation_weight = (params.dig(:portfolio, :allocation_weight) || params[:allocation_weight]).to_f

    if allocation_name.blank?
      @portfolio.errors.add(:allocations, "Allocation name cannot be blank")
      return
    end

    if @portfolio.allocations.exists?(name: allocation_name)
      @portfolio.errors.add(:allocations, "An allocation with this name already exists")
      return
    end

    allocation = @portfolio.allocations.build(
      name: allocation_name,
      percentage: allocation_weight,
      enabled: true
    )

    unless allocation.save
      @portfolio.errors.add(:allocations, "Failed to create allocation: #{allocation.errors.full_messages.join(', ')}")
    end
  end

  def validate_allocation_total
    return if @portfolio.errors.any?

    total_allocation = @portfolio.allocations.sum do |allocation|
      allocation.enabled ? (allocation.percentage.to_f / 100.0) : 0
    end

    if total_allocation > 1.0
      @portfolio.errors.add(:allocations, "Total allocations cannot exceed 100%")
    end
  end

  def handle_allocation_failure
    raw_tickers = @portfolio.tickers || []
    weights = @portfolio.weights || {}

    @tickers = tickers_from_hash(raw_tickers)
    @weights = weights
    @allocations = @portfolio.allocations
    @adjusted_weights = WeightCalculator.new(
      weights: @weights,
      allocations: @allocations
    ).adjusted_weights

    render :show, status: :unprocessable_entity
  end

  # Copy allocations from an original portfolio to build new Allocation objects.
  # Note: These allocations are not yet associated with a portfolio and must be
  # assigned to a portfolio before saving (e.g., @portfolio.allocations = copy_allocations_from(original))
  def copy_allocations_from(original_portfolio)
    original_portfolio.allocations.map do |alloc|
      Allocation.new(
        name: alloc.name,
        percentage: alloc.percentage,
        enabled: alloc.enabled
      )
    end
  end
end
