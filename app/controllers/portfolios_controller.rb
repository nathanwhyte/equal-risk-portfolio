class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  def index
    @portfolios = Portfolio.all
  end

  def show
    # Check if viewing a specific version via URL segment
    if params[:version_number].present?
      @version = @portfolio.portfolio_versions.by_version(params[:version_number]).first

      unless @version
        redirect_to @portfolio, alert: "Version not found"
        return
      end

      # Use version data for display
      @tickers = @version.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
      @weights = @version.weights
      @viewing_version = @version
    else
      # Use latest version data (or fallback to stored portfolio data)
      latest = @portfolio.latest_version
      if latest
        @tickers = latest.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
        @weights = latest.weights
      else
        # Fallback to stored portfolio data (for backward compatibility)
        @tickers = @portfolio.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
        @weights = @portfolio.weights
      end
      @viewing_version = nil
    end

    # Create adjusted weights for display (don't mutate original weights)
    @adjusted_weights = @weights.dup

    # Note: Allocations are not versioned, so use current portfolio allocations
    @allocations = @portfolio.allocations

    # IDEA: disable allocations by default on page load

    if !@allocations.nil?
      # Apply allocation adjustments (same logic as existing show action)
      allocation_sum = 0
      @allocations.each do |_name, allocation_data|
        allocation = normalize_allocation_value(allocation_data)
        if allocation[:enabled]
          allocation_sum += (allocation[:weight].to_f / 100.0)
        end
      end

      allocation_adjustment = [ 1.0 - allocation_sum, 0.0 ].max

      @adjusted_weights.each do |ticker, weight|
        @adjusted_weights[ticker] = weight * allocation_adjustment
      end
    end

    Rails.logger.info "\nPortfolio #{@portfolio.name} with tickers #{@tickers.map(&:symbol)} and weights #{@weights}\n"
  end

  def new
    @portfolio = Portfolio.new
    @tickers = cached_tickers
    @count = cached_tickers.length
  end

  def create
    @portfolio = Portfolio.new

    @portfolio.name = params[:portfolio][:name]
    tickers = cached_tickers

    # Convert Ticker objects to hash format for storage
    ticker_symbols = tickers.map(&:symbol)
    tickers_hash = tickers.map { |ticker| { "symbol" => ticker.symbol, "name" => ticker.name } }

    if ticker_symbols.length <= 0
      @portfolio.errors.add(:tickers, "must include at least one ticker")
      @tickers = cached_tickers
      @count = cached_tickers.length
      render :new, status: :unprocessable_entity
      return
    end

    begin
      @portfolio.weights = call_math_engine(ticker_symbols)
    rescue => e
      Rails.logger.error "API call failed: #{e.message}"
      @portfolio.errors.add(:base, "There was a problem creating the portfolio. Please try again.")
      @tickers = cached_tickers
      @count = cached_tickers.length
      render :new, status: :unprocessable_entity
      return
    end

    # Set tickers in hash format for storage
    @portfolio.tickers = tickers_hash

    Rails.logger.info "\n\nPortfolio #{@portfolio.name} created with tickers #{ticker_symbols} and weights #{@portfolio.weights}\n\n"

    if params[:commit] == "Search"
      redirect_to tickers_search_path(query: params[:query])
    else
      if @portfolio.save
        @portfolio.create_initial_version
        redirect_to @portfolio, notice: "Portfolio was successfully created."
      else
        @tickers = cached_tickers
        @count = cached_tickers.length
        render :new, status: :unprocessable_entity
      end
    end

    clear_cached_tickers
  end

  def edit
    # Load tickers from latest version (or fallback to stored portfolio data)
    latest = @portfolio.latest_version
    if latest
      tickers = latest.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
    else
      # Fallback to stored portfolio data (for backward compatibility)
      tickers = @portfolio.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
    end
    write_cached_tickers(tickers, @portfolio.id)
    @count = tickers.length
    @tickers = tickers
  end

  def update
    # Handle allocations-only updates from the show page
    # Check both top-level and nested params (form_with nests, button_to doesn't)
    if params[:update_allocations] == "true" || params.dig(:portfolio, :update_allocations) == "true"
      handle_allocations_update
      return
    end

    # Handle regular portfolio updates from the edit page
    tickers = cached_tickers(@portfolio.id)
    @portfolio.name = portfolio_params[:name]

    # Calculate new weights before transaction
    begin
      new_weights = call_math_engine(tickers.map { |ticker| ticker.symbol })
    rescue => e
      Rails.logger.error "API call failed: #{e.message}"
      @portfolio.errors.add(:base, "There was a problem updating the portfolio. Please try again.")
      @tickers = tickers
      @count = tickers.length
      render :edit, status: :unprocessable_entity
      return
    end

    # Convert tickers to hash format for version storage
    tickers_hash = tickers.map { |ticker| { "symbol" => ticker.symbol, "name" => ticker.name } }

    # Wrap version creation/update and portfolio update in a transaction for atomicity
    save_succeeded = false
    success_message = "Portfolio was successfully updated."
    Portfolio.transaction do
      # Check if this is a "Create New Version" request (from standalone version form)
      if params[:create_new_version] == "true" || params[:commit] == "Create New Version"
        # Extract version metadata from portfolio_version params
        version_params = params[:portfolio_version] || {}
        version_title = version_params[:title]&.strip.presence
        version_notes = version_params[:notes]&.strip.presence

        # Create a new version with the new tickers and weights
        @portfolio.create_new_version(
          tickers: tickers_hash,
          weights: new_weights,
          title: version_title,
          notes: version_notes
        )

        success_message = "New Version created, Portfolio successfully updated."
      else
        # "Update Current Version" - update the latest version instead of creating a new one
        @portfolio.update_latest_version(
          tickers: tickers_hash,
          weights: new_weights
        )
      end

      # Update portfolio table with new values (for backward compatibility/cache)
      @portfolio.tickers = tickers_hash
      @portfolio.weights = new_weights

      if @portfolio.save
        save_succeeded = true
      else
        raise ActiveRecord::Rollback
      end
    end

    # Check if save was successful
    if save_succeeded
      redirect_to @portfolio, notice: success_message
    else
      @tickers = tickers
      @count = tickers.length
      render :edit, status: :unprocessable_entity
    end

    clear_cached_tickers(@portfolio.id)
  end

  def destroy
    @portfolio.destroy
    redirect_to portfolios_url, notice: "Portfolio was successfully destroyed."
  end

  private

  def set_portfolio
    @portfolio = Portfolio.find(params.expect(:id))
  end

  def portfolio_params
    params.expect(portfolio: [ :name, :tickers, :allocations ])
  end

  def handle_allocations_update
    # Initialize allocations hash if nil
    current_allocations = @portfolio.allocations || {}
    new_allocations = current_allocations.deep_dup

    # Normalize existing allocations to new structure
    normalize_allocations_hash(new_allocations)

    # Handle toggle enabled/disabled
    if params[:toggle_allocation].present?
      allocation_name = params[:toggle_allocation]
      if new_allocations[allocation_name].present?
        allocation = normalize_allocation_value(new_allocations[allocation_name])
        new_allocations[allocation_name] = {
          "weight" => allocation[:weight],
          "enabled" => !allocation[:enabled]
        }
      end
    end

    # Handle removal
    if params[:remove_allocation].present?
      allocation_name = params[:remove_allocation]
      new_allocations = new_allocations.except(allocation_name)
    end

    # Handle addition
    if params[:allocation_name].present? && params[:allocation_weight].present?
      allocation_name = params[:allocation_name].strip
      allocation_weight = params[:allocation_weight].to_f

      if allocation_name.blank?
        @portfolio.errors.add(:allocations, "Allocation name cannot be blank")
      elsif allocation_weight <= 0 || allocation_weight > 100
        @portfolio.errors.add(:allocations, "Allocation weight must be between 0 and 100")
      elsif new_allocations.any? { |name, _| name.downcase == allocation_name.downcase }
        @portfolio.errors.add(:allocations, "An allocation with this name already exists")
      else
        new_allocations[allocation_name] = {
          "weight" => allocation_weight,
          "enabled" => true
        }
      end
    end

    # Validate total allocations don't exceed 100%
    unless @portfolio.errors.any?
      total_allocation = new_allocations.sum do |_name, data|
        allocation = normalize_allocation_value(data)
        allocation[:enabled] ? (allocation[:weight].to_f / 100.0) : 0
      end

      if total_allocation > 1.0
        @portfolio.errors.add(:allocations, "Total allocations cannot exceed 100%")
      end
    end

    # Only assign new allocations if there are no errors
    unless @portfolio.errors.any?
      @portfolio.allocations = new_allocations
    end

    Rails.logger.info "Saving allocations: #{@portfolio.allocations.inspect}"

    if @portfolio.errors.empty? && @portfolio.save
      redirect_to @portfolio, notice: "Allocations were successfully updated."
    else
      Rails.logger.error "Failed to save allocations: #{@portfolio.errors.full_messages.inspect}"
      # Load tickers from latest version (or fallback to stored portfolio data)
      latest = @portfolio.latest_version
      if latest
        @tickers = latest.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
        @adjusted_weights = calculate_adjusted_weights_from_version(latest, @portfolio)
      else
        @tickers = @portfolio.tickers.map { |ticker| Ticker.new(symbol: ticker["symbol"], name: ticker["name"]) }
        @adjusted_weights = calculate_adjusted_weights(@portfolio)
      end
      render :show, status: :unprocessable_entity
    end
  end

  # Calculate adjusted weights based on allocations
  # Adjustment formula:
  # If allocations sum to X%, then stock weights are adjusted by (1 - X)
  # Example: 20% bonds allocation ? stock weights multiplied by 0.8
  # Guard against negative adjustments if allocations exceed 100%
  def calculate_adjusted_weights(portfolio)
    adjusted_weights = portfolio.weights.dup

    return adjusted_weights if portfolio.allocations.nil?

    # Only count enabled allocations (normalize in memory for calculation)
    allocation_sum = 0
    portfolio.allocations.each do |_name, allocation_data|
      allocation = normalize_allocation_value(allocation_data)
      if allocation[:enabled]
        allocation_sum += (allocation[:weight].to_f / 100.0)
      end
    end

    allocation_adjustment = [ 1.0 - allocation_sum, 0.0 ].max

    adjusted_weights.each do |ticker, weight|
      adjusted_weights[ticker] = weight * allocation_adjustment
    end

    adjusted_weights
  end

  # Calculate adjusted weights from a version (for error handling)
  def calculate_adjusted_weights_from_version(version, portfolio)
    adjusted_weights = version.weights.dup

    return adjusted_weights if portfolio.allocations.nil?

    # Only count enabled allocations (normalize in memory for calculation)
    allocation_sum = 0
    portfolio.allocations.each do |_name, allocation_data|
      allocation = normalize_allocation_value(allocation_data)
      if allocation[:enabled]
        allocation_sum += (allocation[:weight].to_f / 100.0)
      end
    end

    allocation_adjustment = [ 1.0 - allocation_sum, 0.0 ].max

    adjusted_weights.each do |ticker, weight|
      adjusted_weights[ticker] = weight * allocation_adjustment
    end

    adjusted_weights
  end

  # Normalize allocation value to hash format (handles backward compatibility)
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

  # Normalize allocations hash (in-place)
  def normalize_allocations_hash(allocations)
    allocations.each do |name, value|
      allocation = normalize_allocation_value(value)
      allocations[name] = {
        "weight" => allocation[:weight],
        "enabled" => allocation[:enabled]
      }
    end
  end

  def call_math_engine(tickers)
    body  = {
      tickers: tickers
    }.to_json

    response = HTTParty.post(
      "#{ENV["API_URL"]}/calculate",
      body: body,
      headers: {
        "Content-Type" => "application/json"
      }
    )

    Rails.logger.info "\n\nResponse from math engine: #{response.parsed_response}\n\n"

    unmapped_weights = response.parsed_response["weights"]

    weights  = {}
    unmapped_weights.map do |pair|
      weights[pair["ticker"]] = pair["weight"].to_f
    end

    weights
  end
end
