module PortfolioDisplayHelper
  def version_select_options(portfolio, viewing_version)
    selected_number = viewing_version&.version_number

    portfolio.portfolio_versions.recent.map do |version|
      label = version.title.presence || "v#{version.version_number}"
      url = version_portfolio_path(portfolio, version.version_number)
      [ label, url, { selected: version.version_number == selected_number } ]
    end
  end

  def allocation_badge_class(portfolio)
    if portfolio.allocations.present? && portfolio.allocations.values.any? { |allocation| allocation_enabled?(allocation) }
      "badge badge-sm badge-warning"
    else
      ""
    end
  end

  def allocation_toggle_class(enabled)
    enabled ? "btn btn-xs btn-ghost" : "btn btn-xs btn-success btn-soft"
  end

  private

  def allocation_enabled?(allocation)
    if allocation.is_a?(Hash)
      allocation["enabled"] == true || allocation[:enabled] == true
    else
      true
    end
  end
end
