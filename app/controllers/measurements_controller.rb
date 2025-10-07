class MeasurementsController < ApplicationController
  layout "main"

  def index
    @measurements = Measurement.where(submitter_id: Current.user.id)
  end

  def status
    @measurement = Measurement.find(params[:id])
    render json: { id: @measurement.id, status: @measurement.status }
  end

  def create
    @measurement = Measurement.new(
      params.require(:measurement).permit(:turbidity, :actual_bod, :actual_cod)
    )
    @measurement.submitter = Current.user

    respond_to do |format|
      if @measurement.save
        format.json { render json: @measurement, status: :created }
      else
        format.json { render status: :unprocessable_entity }
      end
    end
  end
end
