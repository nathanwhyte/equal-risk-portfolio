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
      allocations: allocations,
      title: "Create \"#{name}\"",
      notes: "",
      version_number: 1
    )
  end

  # Update the latest version with new tickers and weights
  # Used when "Update Current Version" is clicked (no new version created)
  def update_latest_version(tickers:, weights:)
    latest = latest_version
    if latest
      latest.update!(
        tickers: tickers || [],
        weights: weights || {},
        allocations: allocations
      )
    else
      # If no version exists, create initial version
      create_initial_version
    end
  end

  # Create a new version with the provided tickers and weights
  # This is called when "Create New Version" is clicked
  def create_new_version(tickers:, weights:, title: nil, notes: nil)
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

  # Manual version creation method (kept for backward compatibility)
  # Creates version from current state before update
  def create_version_with_current_state(title: nil, notes: nil)
    return unless persisted?

    # Use row-level locking to prevent race conditions on version_number
    with_lock do
      next_number = portfolio_versions.maximum(:version_number).to_i + 1

      portfolio_versions.create!(
        tickers: current_tickers,
        weights: current_weights,
        allocations: allocations,
        title: title,
        notes: notes,
        version_number: next_number
      )
    end
  end
end
