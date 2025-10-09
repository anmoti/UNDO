class MeasurementsController < ApplicationController
  layout "main"

  def index
    @measurements = Measurement.where(submitter_id: Current.user.id)
  end

  def show
    @measurement = Measurement.find_by(id: params[:id], submitter_id: Current.user.id)

    if @measurement
      render json: @measurement
    else
      # 他のユーザーのデータにアクセスしようとした場合や、データが存在しない場合
      render json: { error: "Not Found" }, status: :not_found
    end
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

    @measurement.predicted_bod = helpers.estimate_bod(@measurement.turbidity)
    @measurement.predicted_cod = helpers.estimate_cod(@measurement.turbidity)
    @measurement.status = :predicted

    respond_to do |format|
      if @measurement.save
        format.json { render json: @measurement, status: :created }
      else
        format.json { render status: :unprocessable_entity }
      end
    end
  end
end
