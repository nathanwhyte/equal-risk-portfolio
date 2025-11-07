module PortfolioAllocations
  extend ActiveSupport::Concern

  private

  def handle_allocations_update
    current_allocations = @portfolio.allocations || {}
    new_allocations = normalize_allocations_hash(current_allocations.deep_dup)

    toggle_allocation(new_allocations) if params[:toggle_allocation].present?
    remove_allocation(new_allocations) if params[:remove_allocation].present?
    add_allocation(new_allocations) if params[:allocation_name].present? && params[:allocation_weight].present?

    validate_allocation_total(new_allocations)

    unless @portfolio.errors.any?
      @portfolio.allocations = new_allocations
    end

    Rails.logger.info "Saving allocations: #{@portfolio.allocations.inspect}"

    if @portfolio.errors.empty? && @portfolio.save
      redirect_to @portfolio, notice: "Allocations were successfully updated."
    else
      Rails.logger.error "Failed to save allocations: #{@portfolio.errors.full_messages.inspect}"
      handle_allocation_failure
    end
  end

  def toggle_allocation(allocations)
    allocation_name = params[:toggle_allocation]
    return unless allocations[allocation_name].present?

    allocation = normalize_allocation_value(allocations[allocation_name])
    allocations[allocation_name] = {
      "weight" => allocation[:weight],
      "enabled" => !allocation[:enabled]
    }
  end

  def remove_allocation(allocations)
    allocation_name = params[:remove_allocation]
    allocations.except!(allocation_name)
  end

  def add_allocation(allocations)
    allocation_name = params[:allocation_name].strip
    allocation_weight = params[:allocation_weight].to_f

    if allocation_name.blank?
      @portfolio.errors.add(:allocations, "Allocation name cannot be blank")
    elsif allocation_weight <= 0 || allocation_weight > 100
      @portfolio.errors.add(:allocations, "Allocation weight must be between 0 and 100")
    elsif allocations.any? { |name, _| name.downcase == allocation_name.downcase }
      @portfolio.errors.add(:allocations, "An allocation with this name already exists")
    else
      allocations[allocation_name] = {
        "weight" => allocation_weight,
        "enabled" => true
      }
    end
  end

  def validate_allocation_total(allocations)
    return if @portfolio.errors.any?

    total_allocation = allocations.sum do |_name, data|
      allocation = normalize_allocation_value(data)
      allocation[:enabled] ? (allocation[:weight].to_f / 100.0) : 0
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

  def normalize_allocation_value(value)
    if value.is_a?(Hash)
      {
        weight: value["weight"] || value[:weight] || value.to_f,
        enabled: value["enabled"] != false && value[:enabled] != false
      }
    else
      {
        weight: value.to_f,
        enabled: true
      }
    end
  end

  def normalize_allocations_hash(allocations)
    allocations.each do |name, value|
      allocation = normalize_allocation_value(value)
      allocations[name] = {
        "weight" => allocation[:weight],
        "enabled" => allocation[:enabled]
      }
    end
    allocations
  end
end
