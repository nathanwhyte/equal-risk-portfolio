module PortfolioCapAndRedistributeOptions
  extend ActiveSupport::Concern

  private

  def get_param(key)
    params[key] || params.dig(:portfolio, key)
  end

  def handle_cap_and_redistribute_options_update
    Portfolio.transaction do
      # Check both top-level and nested params (form_with nests, button_to doesn't)
      toggle_cap_and_redistribute_option if get_param(:toggle_cap_and_redistribute_option).present?
      remove_cap_and_redistribute_option if get_param(:remove_cap_and_redistribute_option).present?
      clear_cap_and_redistribute_options if get_param(:clear_cap_and_redistribute_options).present?

      # For adding, check nested params from form_with
      cap_percentage = get_param(:cap_percentage)
      top_n = get_param(:top_n)
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

  # Deactivate all cap and redistribute options for this portfolio
  # Note: Uses update_all to bypass callbacks for performance
  def clear_cap_and_redistribute_options
    @portfolio.cap_and_redistribute_options.all.update_all(active: false)
  end

  def toggle_cap_and_redistribute_option
    option_id = get_param(:toggle_cap_and_redistribute_option)
    option = @portfolio.cap_and_redistribute_options.find_by(id: option_id)

    unless option
      @portfolio.errors.add(:cap_and_redistribute_options, "Option not found")
      return
    end

    unless option.update(active: !option.active)
      @portfolio.errors.add(:cap_and_redistribute_options, "Failed to update option: #{option.errors.full_messages.join(', ')}")
      return
    end

    if option.active
      option.activate!
      # Calculate and store weights if they don't exist
      calculate_and_store_weights_for_option(option) unless option.has_weights?
    end
  end

  def remove_cap_and_redistribute_option
    option_id = get_param(:remove_cap_and_redistribute_option)
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
    cap_percentage = get_param(:cap_percentage).to_f
    top_n = get_param(:top_n).to_i

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
      return
    end

    # Mark the new option as active and deactivate all others
    option.activate!

    # Calculate and store weights for the new option
    calculate_and_store_weights_for_option(option)
  end

  def calculate_and_store_weights_for_option(option)
    return if option.has_weights?

    # Load tickers from portfolio
    raw_tickers = @portfolio.tickers || []
    tickers_arr = Array(raw_tickers)
    tickers_list = tickers_arr.map { |ticker| ticker["symbol"] || ticker[:symbol] }

    # Calculate weights with cap and redistribute settings
    begin
      new_weights = math_engine_client.calculate_weights(
        tickers: tickers_list,
        cap: option.cap_percentage,
        top_n: option.top_n
      )

      option.update!(weights: new_weights)
    rescue MathEngineClient::Error => e
      Rails.logger.error "Failed to calculate weights for option: #{e.message}"
      @portfolio.errors.add(:cap_and_redistribute_options, "Failed to calculate weights: #{e.message}")
      raise ActiveRecord::Rollback
    end
  end

  def handle_cap_and_redistribute_failure
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

  def copy_cap_and_redistribute_options_from(original_portfolio)
    return [] unless original_portfolio.present?

    # Get tickers from the new portfolio (not the original)
    raw_tickers = @portfolio.tickers || []
    tickers_list = Array(raw_tickers).map { |ticker| ticker["symbol"] || ticker[:symbol] }

    # Copy each option and calculate weights for the new portfolio's tickers
    original_portfolio.cap_and_redistribute_options.map do |original_option|
      new_option = @portfolio.cap_and_redistribute_options.build(
        cap_percentage: original_option.cap_percentage,
        top_n: original_option.top_n,
        active: false
      )

      # Calculate weights for the new portfolio's tickers
      if tickers_list.any?
        begin
          new_weights = math_engine_client.calculate_weights(
            tickers: tickers_list,
            cap: new_option.cap_percentage,
            top_n: new_option.top_n
          )
          new_option.weights = new_weights
        rescue MathEngineClient::Error => e
          Rails.logger.error "Failed to calculate weights for copied option: #{e.message}"
          # Continue without weights - they can be calculated later when the option is activated
        end
      end

      new_option
    end
  end
end
