class Portfolio < ApplicationRecord
  belongs_to :copy_of, class_name: "Portfolio", optional: true, foreign_key: "copy_of_id"

  has_many :portfolio_versions, dependent: :destroy
  has_many :copies, class_name: "Portfolio", foreign_key: "copy_of_id"

  # Scopes for version queries
  def latest_version
    portfolio_versions.chronological.first
  end

  def base_version
    portfolio_versions.chronological.last
  end

  def version_at(version_number)
    portfolio_versions.by_version(version_number).first
  end

  # Get current tickers from latest version, fallback to stored value
  def current_tickers
    latest_version&.tickers || tickers || []
  end

  # Get current weights from latest version, fallback to stored value
  def current_weights
    latest_version&.weights || weights || {}
  end

  def create_initial_version
    portfolio_versions.create!(
      tickers: tickers || [],
      weights: weights || {},
      title: "Create \"#{name}\"",
      notes: "",
      version_number: 1
    )
  end

  # Update the latest version with new tickers and weights
  # Used when "Update Current Version" is clicked (no new version created)
  def update_latest_version(tickers:, weights:, cap: nil, top_n: nil)
    latest = latest_version
    if latest
      latest.update!(
        tickers: tickers || [],
        weights: weights || {},
        cap_percentage: cap,
        top_n: top_n
      )
    else
      # If no version exists, create initial version
      create_initial_version
    end
  end

  # Create a new version with the provided tickers and weights
  # This is called when "Create New Version" is clicked
  def create_new_version(tickers:, weights:, title: nil, notes: nil, cap: nil, top_n: nil)
    return unless persisted?

    # Use row-level locking to prevent race conditions on version_number
    with_lock do
      next_number = portfolio_versions.maximum(:version_number).to_i + 1

      portfolio_versions.create!(
        tickers: tickers || [],
        weights: weights || {},
        cap_percentage: cap,
        top_n: top_n,
        title: title,
        notes: notes,
        version_number: next_number
      )
    end
  end

  # Pretty-print portfolio information for debugging and console output
  def pretty_print(verbose: false)
    output = []
    output << "=" * 80
    name_line = "Portfolio: #{name}"
    name_line += " (portfolio.name)" if verbose
    output << name_line
    output << "=" * 80
    id_line = "ID: #{id}"
    id_line += " (portfolio.id)" if verbose
    output << id_line
    created_line = "Created: #{created_at}"
    created_line += " (portfolio.created_at)" if verbose
    output << created_line
    updated_line = "Updated: #{updated_at}"
    updated_line += " (portfolio.updated_at)" if verbose
    output << updated_line
    output << ""

    # Version information
    version_count = portfolio_versions.count
    latest = latest_version
    base = base_version
    versions_line = "Versions: #{version_count}"
    versions_line = "Versions (portfolio.portfolio_versions, portfolio.latest_version, portfolio.base_version): #{version_count}" if verbose
    output << versions_line
    if latest
      output << "  Latest: Version #{latest.version_number} (#{latest.created_at})"
      output << "    Title: #{latest.title}" if latest.title.present?
    end
    if base && base != latest
      output << "  Base: Version #{base.version_number} (#{base.created_at})"
    end
    output << ""

    # Current tickers and weights
    current_t = current_tickers
    current_w = current_weights

    table_line = "Current Tickers & Weights:"
    table_line = "Current Tickers & Weights (portfolio.current_tickers, portfolio.current_weights):" if verbose
    output << table_line

    if current_t.present? || current_w.present?
      # Collect all symbols from both tickers and weights
      all_symbols = []
      all_symbols.concat(current_w.keys.map(&:to_s)) if current_w.present?
      current_t.each { |t| all_symbols << (t["symbol"] || t[:symbol]).to_s } if current_t.present?
      all_symbols.uniq!

      # Build table rows
      rows = all_symbols.map do |symbol|
        # Get ticker name
        ticker_info = current_t&.find { |t| (t["symbol"] || t[:symbol]) == symbol }
        ticker_name = ticker_info ? (ticker_info["name"] || ticker_info[:name]) : nil
        name_display = ticker_name.present? ? ticker_name : "(none)"

        # Get weight
        weight = current_w&.[](symbol.to_s)
        weight_display = weight.present? ? format("%.2f", (weight.to_f)) + "%" : "(none)"
        weight_value = weight.present? ? weight.to_f : nil

        { symbol: symbol.to_s, name: name_display, weight: weight_display, weight_value: weight_value }
      end

      # Sort by weight descending (treat nil as -1 for sorting)
      rows.sort_by! { |r| -(r[:weight_value] || -1) }

      # Calculate column widths
      symbol_width = [ 6, rows.map { |r| r[:symbol].length }.max || 0 ].max
      name_width = [ 20, rows.map { |r| r[:name].length }.max || 0 ].max
      weight_width = [ 10, rows.map { |r| r[:weight].length }.max || 0 ].max

      # Print header
      output << "  #{'Symbol'.ljust(symbol_width)} | #{'Name'.ljust(name_width)} | #{'Weight'.ljust(weight_width)}"
      output << "  #{'-' * symbol_width} | #{'-' * name_width} | #{'-' * weight_width}"

      # Print rows
      rows.each do |row|
        output << "  #{row[:symbol].ljust(symbol_width)} | #{row[:name].ljust(name_width)} | #{row[:weight].ljust(weight_width)}"
      end
    else
      output << "  (none)"
    end
    output << ""

    # Allocations
    allocations_line = "Allocations:"
    allocations_line = "Allocations (portfolio.allocations):" if verbose
    output << allocations_line
    if allocations.present?
      allocations.each do |name, allocation_data|
        if allocation_data.is_a?(Hash)
          weight = allocation_data["weight"] || allocation_data[:weight] || 0
          enabled = allocation_data["enabled"] != false
          status = enabled ? "enabled" : "disabled"
          output << "  #{name.ljust(20)} | #{format("%.2f", (weight.to_f))}% | #{status}"
        else
          weight = allocation_data.to_f
          output << "  #{name.ljust(20)} | #{format("%.2f", (weight.to_f))}%"
        end
      end
    else
      output << "  (none)"
    end
    output << ""

    # Cap and Redistribute options
    cap_line = "Cap and Redistribute Options:"
    cap_line = "Cap and Redistribute Options (portfolio.latest_version.cap_percentage, portfolio.latest_version.top_n):" if verbose
    output << cap_line
    if latest
      cap = latest.cap_percentage
      top_n = latest.top_n
      if cap.present? || top_n.present?
        if cap.present?
          output << "  Cap Percentage: #{format("%.2f", (cap.to_f * 100))}%"
        else
          output << "  Cap Percentage: (not set)"
        end
        if top_n.present?
          output << "  Top N Stocks: #{top_n}"
        else
          output << "  Top N Stocks: (not set)"
        end
      else
        output << "  (none)"
      end
    else
      output << "  (no versions)"
    end
    output << ""

    output << "=" * 80
    output.join("\n")
  end
end
