class PortfoliosController < ApplicationController
  include CallLambda

  before_action :set_portfolio, only: %i[ show edit update destroy ]

  # GET /portfolios or /portfolios.json
  def index
    @portfolios = Portfolio.all
  end

  # GET /portfolios/1 or /portfolios/1.json
  # NOTE: should cache this somehow, currently recalling lambda each refresh
  def show
    @tickers = @portfolio.tickers.map { |ticker| Ticker.new(ticker) }
  end

  # GET /portfolios/new
  def new
    @portfolio = Portfolio.new
    @tickers = cached_tickers
    @count = cached_tickers.length
  end

  # GET /portfolios/1/edit
  # TODO: cache is clear at this point, either reload cache or use a different approach
  def edit
    @count = @portfolio.tickers.length
  end

  # POST /portfolios or /portfolios.json
  def create
    @portfolio = Portfolio.new

    @portfolio.name = params[:portfolio][:name]
    @portfolio.tickers = cached_tickers

    ticker_symbols = @portfolio.tickers.map { |ticker| ticker["symbol"] }

    if ticker_symbols.length <= 0
      return
    end

    weights = call_lambda(ticker_symbols)

    @portfolio.weights = weights

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

    clear_cached_tickers
  end

  # PATCH/PUT /portfolios/1 or /portfolios/1.json
  def update
    tickers = cached_tickers

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
end
