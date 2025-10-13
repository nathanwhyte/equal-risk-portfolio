class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  # GET /portfolios or /portfolios.json
  def index
    @portfolios = Portfolio.all
  end

  # GET /portfolios/1 or /portfolios/1.json
  def show
  end

  # GET /portfolios/new
  def new
    clear_cached_tickers
    @count = 0
    @portfolio = Portfolio.new
    @portfolio.tickers = read_cached_tickers
  end

  # GET /portfolios/1/edit
  def edit
    @count = 0
  end

  # POST /portfolios or /portfolios.json
  def create
    @portfolio = Portfolio.new
    @portfolio.tickers = read_cached_tickers

    if params[:commit] == "Search"
      redirect_to tickers_search_path(query: params[:query])
    else
      respond_to do |format|
        if @portfolio.save
          format.html { redirect_to @portfolio, notice: "Portfolio was successfully created." }
          format.json { render :show, status: :created, location: @portfolio }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @portfolio.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /portfolios/1 or /portfolios/1.json
  def update
    tickers = read_cached_tickers

    respond_to do |format|
      if @portfolio.update(tickers: tickers)
        format.html { redirect_to @portfolio, notice: "Portfolio was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @portfolio }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @portfolio.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /portfolios/1 or /portfolios/1.json
  def destroy
    @portfolio.destroy!

    respond_to do |format|
      format.html { redirect_to portfolios_path, notice: "Portfolio was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_portfolio
      @portfolio = Portfolio.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def portfolio_params
      params.expect(portfolio: [ :name, :tickers ])
    end

    def read_cached_tickers
      tickers = []
      cached_tickers.map do |ticker|
        tickers << ticker["symbol"]
      end

      tickers
    end
end
