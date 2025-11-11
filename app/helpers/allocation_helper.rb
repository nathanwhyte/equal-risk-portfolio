module AllocationHelper
  def allocation_toggle_class(enabled)
    enabled ? "btn btn-xs btn-ghost" : "btn btn-xs btn-success btn-soft"
  end

  def allocation_badge_class(portfolio)
    if portfolio.allocations.present? && portfolio.allocations.any?(&:enabled)
      "badge badge-sm badge-warning"
    else
      ""
    end
  end
end
