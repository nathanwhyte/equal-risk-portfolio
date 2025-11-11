class CreateAllocations < ActiveRecord::Migration[8.1]
  def up
    create_table :allocations, if_not_exists: true do |t|
      t.references :portfolio, null: false, foreign_key: true, type: :uuid

      t.string :name, null: false
      t.float :percentage, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    # Migrate existing JSONB allocations data to new table
    migrate_jsonb_allocations_to_table
  end

  def down
    # Migrate data back to JSONB before dropping table
    migrate_table_allocations_to_jsonb

    drop_table :allocations
  end

  private

  def migrate_jsonb_allocations_to_table
    say "Migrating allocations from JSONB to allocations table..."

    migrated_count = 0
    skipped_count = 0
    error_count = 0

    Portfolio.find_each do |portfolio|
      allocations_data = portfolio.read_attribute(:allocations)

      # Skip if nil or not a hash
      unless allocations_data.is_a?(Hash)
        skipped_count += 1
        next
      end

      # Skip if empty hash
      if allocations_data.empty?
        skipped_count += 1
        next
      end

      # Migrate each allocation
      allocations_data.each do |name, data|
        next unless data.is_a?(Hash)

        begin
          # Extract percentage from "weight" or "percentage" key (backward compatibility)
          percentage = data["weight"] || data["percentage"]
          next if percentage.nil?

          # Extract enabled, default to true if missing
          enabled = data.fetch("enabled", true)

          # Create allocation record
          portfolio.allocations.create!(
            name: name.to_s,
            percentage: percentage.to_f,
            enabled: enabled
          )

          migrated_count += 1
        rescue StandardError => e
          error_count += 1
          say "Error migrating allocation '#{name}' for portfolio #{portfolio.id}: #{e.message}", true
        end
      end
    end

    say "Migration complete: #{migrated_count} allocations migrated, #{skipped_count} portfolios skipped, #{error_count} errors"
  end

  def migrate_table_allocations_to_jsonb
    say "Migrating allocations from table back to JSONB..."

    migrated_count = 0

    Portfolio.includes(:allocations).find_each do |portfolio|
      next if portfolio.allocations.empty?

      # Build hash structure matching original JSONB format
      allocations_hash = {}
      portfolio.allocations.each do |allocation|
        allocations_hash[allocation.name] = {
          "weight" => allocation.percentage,
          "enabled" => allocation.enabled
        }
      end

      # Update JSONB column directly (bypass validations)
      portfolio.update_column(:allocations, allocations_hash)
      migrated_count += 1
    end

    say "Rollback complete: #{migrated_count} portfolios restored to JSONB format"
  end
end
