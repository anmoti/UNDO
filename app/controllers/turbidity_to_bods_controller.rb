class TurbidityToBodsController < ApplicationController
  before_action :set_turbidity_to_bod, only: %i[ show edit update destroy ]

  # GET /turbidity_to_bods or /turbidity_to_bods.json
  def index
    @turbidity_to_bods = TurbidityToBod.all
  end

  # GET /turbidity_to_bods/1 or /turbidity_to_bods/1.json
  def show
  end

  # GET /turbidity_to_bods/new
  def new
    @turbidity_to_bod = TurbidityToBod.new
  end

  # GET /turbidity_to_bods/1/edit
  def edit
  end

  # POST /turbidity_to_bods or /turbidity_to_bods.json
  def create
    @turbidity_to_bod = TurbidityToBod.new(turbidity_to_bod_params)

    respond_to do |format|
      if @turbidity_to_bod.save
        format.html { redirect_to @turbidity_to_bod, notice: "Turbidity to bod was successfully created." }
        format.json { render :show, status: :created, location: @turbidity_to_bod }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @turbidity_to_bod.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /turbidity_to_bods/1 or /turbidity_to_bods/1.json
  def update
    respond_to do |format|
      if @turbidity_to_bod.update(turbidity_to_bod_params)
        format.html { redirect_to @turbidity_to_bod, notice: "Turbidity to bod was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @turbidity_to_bod }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @turbidity_to_bod.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /turbidity_to_bods/1 or /turbidity_to_bods/1.json
  def destroy
    @turbidity_to_bod.destroy!

    respond_to do |format|
      format.html { redirect_to turbidity_to_bods_path, notice: "Turbidity to bod was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_turbidity_to_bod
      @turbidity_to_bod = TurbidityToBod.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def turbidity_to_bod_params
      params.fetch(:turbidity_to_bod, {})
    end
end
