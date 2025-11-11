module PortfolioCapAndRedistributeOptions
  extend ActiveSupport::Concern

  private

  def handle_cap_and_redistribute_options_update
    Portfolio.transaction do
      # Check both top-level and nested params (form_with nests, button_to doesn't)
      toggle_cap_and_redistribute_option if params[:toggle_cap_and_redistribute_option].present? || params.dig(:portfolio, :toggle_cap_and_redistribute_option).present?
      remove_cap_and_redistribute_option if params[:remove_cap_and_redistribute_option].present? || params.dig(:portfolio, :remove_cap_and_redistribute_option).present?

      # For adding, check nested params from form_with
      cap_percentage = params.dig(:portfolio, :cap_percentage) || params[:cap_percentage]
      top_n = params.dig(:portfolio, :top_n) || params[:top_n]
      add_cap_and_redistribute_option if cap_percentage.present? && top_n.present?

      if @portfolio.errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if @portfolio.errors.empty?
      redirect_to @portfolio, notice: "Cap and redistribute options were successfully updated."
    else
      Rails.logger.error "Failed to save cap and redistribute options: #{@portfolio.errors.full_messages.inspect}"
      handle_cap_and_redistribute_failure
    end
  end

  def toggle_cap_and_redistribute_option
    option_id = params[:toggle_cap_and_redistribute_option] || params.dig(:portfolio, :toggle_cap_and_redistribute_option)
    option = @portfolio.cap_and_redistribute_options.find_by(id: option_id)

    unless option
      @portfolio.errors.add(:cap_and_redistribute_options, "Option not found")
      return
    end

    unless option.update(active: !option.active)
      @portfolio.errors.add(:cap_and_redistribute_options, "Failed to update option: #{option.errors.full_messages.join(', ')}")
    end
  end

  def remove_cap_and_redistribute_option
    option_id = params[:remove_cap_and_redistribute_option] || params.dig(:portfolio, :remove_cap_and_redistribute_option)
    option = @portfolio.cap_and_redistribute_options.find_by(id: option_id)

    unless option
      @portfolio.errors.add(:cap_and_redistribute_options, "Option not found")
      return
    end

    unless option.destroy
      @portfolio.errors.add(:cap_and_redistribute_options, "Failed to remove option")
    end
  end

  def add_cap_and_redistribute_option
    cap_percentage = (params.dig(:portfolio, :cap_percentage) || params[:cap_percentage]).to_f
    top_n = (params.dig(:portfolio, :top_n) || params[:top_n]).to_i

    if cap_percentage <= 0 || cap_percentage > 100
      @portfolio.errors.add(:cap_and_redistribute_options, "Cap percentage must be between 0 and 100")
      return
    end

    if top_n <= 0
      @portfolio.errors.add(:cap_and_redistribute_options, "Top N must be greater than 0")
      return
    end

    # Check if an identical option already exists
    if @portfolio.cap_and_redistribute_options.exists?(
      cap_percentage: cap_percentage / 100.0,
      top_n: top_n
    )
      @portfolio.errors.add(:cap_and_redistribute_options, "An option with these settings already exists")
      return
    end

    option = @portfolio.cap_and_redistribute_options.build(
      cap_percentage: cap_percentage / 100.0,
      top_n: top_n,
      active: false
    )

    unless option.save
      @portfolio.errors.add(:cap_and_redistribute_options, "Failed to create option: #{option.errors.full_messages.join(', ')}")
    end
  end

  def handle_cap_and_redistribute_failure
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
