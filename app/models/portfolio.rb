class Portfolio < ApplicationRecord
  belongs_to :copy_of, class_name: "Portfolio", optional: true, foreign_key: "copy_of_id"

  has_many :allocations, dependent: :destroy
  has_many :cap_and_redistribute_options, dependent: :destroy

  has_many :copies, class_name: "Portfolio", foreign_key: "copy_of_id"

  # Find the active cap and redistribute option for this portfolio
  def active_cap_and_redistribute_option
    cap_and_redistribute_options.active.first
  end

  # Get current tickers from portfolio
  def current_tickers
    tickers || []
  end

  # Get current weights from portfolio
  def current_weights
    weights || {}
  end

  # Pretty-print portfolio information for debugging and console output
  def pretty_print
    output = []
    output << "=" * 80
    output << "Portfolio: #{name}"
    output << "=" * 80
    output << "ID: #{id}"
    output << "Created: #{created_at}"
    output << "Updated: #{updated_at}"

    # Copy information
    if copy_of.present?
      output << "Copy of: #{copy_of.name} (ID: #{copy_of.id})"
    end
    copies_count = copies.count
    output << "Copies: #{copies_count}"
    if copies_count > 0
      copies.each_with_index do |copy, index|
        prefix = index == copies_count - 1 ? "└" : "├"
        output << "#{prefix} #{copy.name} (#{copy.id})"
      end
    end
    output << ""

    # Current tickers and weights
    current_t = current_tickers
    current_w = current_weights

    output << "Current Tickers & Weights:"

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
      output << "│ #{'Symbol'.ljust(symbol_width)} | #{'Name'.ljust(name_width)} | #{'Weight'.ljust(weight_width)}"
      output << "│ #{'-' * symbol_width} | #{'-' * name_width} | #{'-' * weight_width}"

      # Print rows
      rows.each_with_index do |row, index|
        prefix = index == rows.length - 1 ? "└" : "├"
        output << "#{prefix} #{row[:symbol].ljust(symbol_width)} | #{row[:name].ljust(name_width)} | #{row[:weight].ljust(weight_width)}"
      end
    else
      output << "└ (none)"
    end
    output << ""

    # Allocations
    output << "Allocations:"
    if allocations.any?
      # Calculate column widths
      name_width = [ 4, allocations.map { |a| a.name.length }.max || 0 ].max
      percentage_display = allocations.map { |a| format("%.2f", a.percentage) + "%" }
      percentage_width = [ 10, percentage_display.map(&:length).max || 0 ].max
      status_width = [ 6, 8 ].max # "enabled" is 7 chars, "disabled" is 8 chars

      # Print header
      output << "│ #{'Name'.ljust(name_width)} | #{'Percentage'.ljust(percentage_width)} | #{'Status'.ljust(status_width)}"
      output << "│ #{'-' * name_width} | #{'-' * percentage_width} | #{'-' * status_width}"

      # Print rows
      allocations.each_with_index do |allocation, index|
        status = allocation.enabled ? "enabled" : "disabled"
        prefix = index == allocations.length - 1 ? "└" : "├"
        percentage_str = format("%.2f", allocation.percentage) + "%"
        output << "#{prefix} #{allocation.name.ljust(name_width)} | #{percentage_str.ljust(percentage_width)} | #{status.ljust(status_width)}"
      end
    else
      output << "└ (none)"
    end
    output << ""

    # Cap and Redistribute options
    output << "Cap and Redistribute Options:"
    if cap_and_redistribute_options.any?
      cap_and_redistribute_options.each_with_index do |option, option_index|
        is_last_option = option_index == cap_and_redistribute_options.length - 1
        prefix = is_last_option ? "└" : "├"
        active_status = option.active? ? " (active)" : " (inactive)"
        output << "#{prefix} Cap Percentage: #{format("%.2f", (option.cap_percentage * 100))}%#{active_status}"
        continuation = is_last_option ? "  └" : "│ └"
        output << "#{continuation} Top N Stocks: #{option.top_n}"
      end
    else
      output << "└ (none)"
    end
    output << ""

    output << "=" * 80
    output.join("\n")
  end
end
