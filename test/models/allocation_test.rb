require "test_helper"

class AllocationTest < ActiveSupport::TestCase
  def setup
    @portfolio = portfolios(:one)
  end

  test "should be valid with valid attributes" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      name: "Cash",
      percentage: 20.0,
      enabled: true
    )

    assert allocation.valid?
  end

  test "should require name" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      percentage: 20.0,
      enabled: true
    )

    assert_not allocation.valid?
    assert_includes allocation.errors[:name], "can't be blank"
  end

  test "should require percentage" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      name: "Cash",
      enabled: true
    )

    assert_not allocation.valid?
    # Rails validates nil as "is not a number" for numericality
    assert allocation.errors[:percentage].any?
  end

  test "should require percentage greater than zero" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      name: "Cash",
      percentage: 0,
      enabled: true
    )

    assert_not allocation.valid?
    assert_includes allocation.errors[:percentage], "must be greater than 0"
  end

  test "should require percentage less than or equal to 100" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      name: "Cash",
      percentage: 101,
      enabled: true
    )

    assert_not allocation.valid?
    assert_includes allocation.errors[:percentage], "must be less than or equal to 100"
  end

  test "should require enabled to be boolean" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      name: "Cash",
      percentage: 20.0,
      enabled: nil
    )

    assert_not allocation.valid?
    assert_includes allocation.errors[:enabled], "is not included in the list"
  end

  test "should allow percentage exactly 100" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      name: "Cash",
      percentage: 100.0,
      enabled: true
    )

    assert allocation.valid?
  end

  test "should allow percentage exactly 0.01" do
    allocation = Allocation.new(
      portfolio: @portfolio,
      name: "Cash",
      percentage: 0.01,
      enabled: true
    )

    assert allocation.valid?
  end

  test "should belong to portfolio" do
    allocation = allocations(:cash_allocation)
    assert_respond_to allocation, :portfolio
    assert_equal @portfolio, allocation.portfolio
  end

  test "should be destroyed when portfolio is destroyed" do
    portfolio = Portfolio.create!(
      name: "Test Portfolio",
      tickers: [ { symbol: "AAPL", name: "Apple" } ],
      weights: { "AAPL" => 1.0 }
    )

    allocation = portfolio.allocations.create!(
      name: "Cash",
      percentage: 20.0,
      enabled: true
    )

    allocation_id = allocation.id
    portfolio.destroy

    assert_nil Allocation.find_by(id: allocation_id)
  end
end
