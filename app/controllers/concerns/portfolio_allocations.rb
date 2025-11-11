module PortfolioAllocations
  extend ActiveSupport::Concern

  private

  def handle_allocations_update
    Portfolio.transaction do
      toggle_allocation if params[:toggle_allocation].present?
      remove_allocation if params[:remove_allocation].present?
      add_allocation if params[:allocation_name].present? && params[:allocation_weight].present?

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
    allocation_name = params[:toggle_allocation]
    allocation = @portfolio.allocations.find_by(name: allocation_name)

    unless allocation
      @portfolio.errors.add(:allocations, "Allocation not found")
      return
    end

    unless allocation.update(enabled: !allocation.enabled)
      @portfolio.errors.add(:allocations, "Failed to update allocation: #{allocation.errors.full_messages.join(', ')}")
    end
  end

  def remove_allocation
    allocation_name = params[:remove_allocation]
    allocation = @portfolio.allocations.find_by(name: allocation_name)

    unless allocation
      @portfolio.errors.add(:allocations, "Allocation not found")
      return
    end

    unless allocation.destroy
      @portfolio.errors.add(:allocations, "Failed to remove allocation")
    end
  end

  def add_allocation
    allocation_name = params[:allocation_name].strip
    allocation_weight = params[:allocation_weight].to_f

    if allocation_name.blank?
      @portfolio.errors.add(:allocations, "Allocation name cannot be blank")
      return
    end

    if allocation_weight <= 0 || allocation_weight > 100
      @portfolio.errors.add(:allocations, "Allocation weight must be between 0 and 100")
      return
    end

    if @portfolio.allocations.exists?(name: allocation_name)
      @portfolio.errors.add(:allocations, "An allocation with this name already exists")
      return
    end

    allocation = @portfolio.allocations.build(
      name: allocation_name,
      percentage: allocation_weight,
      enabled: false
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
    latest = @portfolio.latest_version
    if latest
      raw_tickers = latest.tickers
      weights = latest.weights
    else
      raw_tickers = @portfolio.tickers
      weights = @portfolio.weights
    end

    @tickers = tickers_from_hash(raw_tickers)
    @weights = weights || {}
    @allocations = @portfolio.allocations
    @adjusted_weights = WeightCalculator.new(
      weights: @weights,
      allocations: @allocations
    ).adjusted_weights

    render :show, status: :unprocessable_entity
  end
end
