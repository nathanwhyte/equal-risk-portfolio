module PortfolioDisplayHelper
  def version_select_options(portfolio, viewing_version)
    selected_number = viewing_version&.version_number

    portfolio.portfolio_versions.chronological.map do |version|
      label = version.title.presence || "v#{version.version_number}"
      url = portfolio_path(portfolio)
      [ label, url, { selected: version.version_number == selected_number } ]
    end
  end

  def cap_and_redistribute_toggle_class(enabled)
    enabled ? "btn btn-disabled text-success btn-xs btn-ghost" : "btn btn-xs btn-accent btn-soft"
  end
end
