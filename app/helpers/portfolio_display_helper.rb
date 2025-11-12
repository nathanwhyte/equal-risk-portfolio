module PortfolioDisplayHelper
  def cap_and_redistribute_toggle_class(enabled)
    enabled ? "btn btn-disabled text-success btn-xs btn-ghost" : "btn btn-xs btn-accent btn-soft"
  end
end
