class Portfolio < ApplicationRecord
  has_many :portfolio_versions, dependent: :destroy

  # Scopes for version queries
  def latest_version
    portfolio_versions.recent.first
  end

  def version_at(version_number)
    portfolio_versions.by_version(version_number).first
  end

  def versions_after(date)
    portfolio_versions.where("created_at > ?", date).recent
  end

  def create_initial_version
      portfolio_versions.create!(
        tickers: tickers || [],
        weights: weights || {},
        allocations: allocations,
        title: "Create \"#{name}\"",
        notes: "",
        version_number: 1
      )
  end

  # Manual version creation method (called from controller when user requests it)
  def create_version_with_current_state(title: nil, notes: nil)
    return unless persisted?

    # Use row-level locking to prevent race conditions on version_number
    with_lock do
      next_number = portfolio_versions.maximum(:version_number).to_i + 1

      portfolio_versions.create!(
        tickers: tickers || [],
        weights: weights || {},
        allocations: allocations,
        title: title,
        notes: notes,
        version_number: next_number
      )
    end
  end
end
