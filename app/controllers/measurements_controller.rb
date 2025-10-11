class MeasurementsController < ApplicationController
  layout "main"
  # before_action :require_company_account, only: [ :index ]

  def index
    # 企業アカウントの場合は店舗でフィルタリング可能
    if params[:store_id].present?
      @store = Current.user.operated_stores.find_by(id: params[:store_id])
      @measurements = @store ? @store.measurements : Measurement.none
    else
       # 全店舗の測定データを取得
       @measurements = Measurement
        .where(store_id: Current.user.operated_stores.select(:id))
        .includes(:store)
    end
  end

  def show
    if Current.user.is_company
      # 企業アカウントは自社店舗の測定データのみアクセス可能
      @measurement = Measurement
        .where(id: params[:id], store_id: Current.user.operated_stores.select(:id))
        .includes(:store)
        .first
    else
      @measurement = Measurement.find_by(id: params[:id], submitter_id: Current.user.id)
    end

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
    permitted_params = params.require(:measurement).permit(:turbidity, :actual_bod, :actual_cod, :store_id)
    @measurement = Measurement.new(permitted_params)

    if Current.user.is_company && !permitted_params[:store_id].present?
      @measurement.submitter = Current.user

      @measurement.predicted_bod = helpers.estimate_bod(@measurement.turbidity)
      @measurement.predicted_cod = helpers.estimate_cod(@measurement.turbidity)
      @measurement.status = :predicted

      respond_to do |format|
        if @measurement.save
          format.json { render json: @measurement, status: :created }
        else
          format.json { render json: { errors: @measurement.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    else
      @measurement.store_id = nil

      @measurement.submitter = Current.user

      @measurement.predicted_bod = helpers.estimate_bod(@measurement.turbidity)
      @measurement.predicted_cod = helpers.estimate_cod(@measurement.turbidity)
      @measurement.status = :predicted

      respond_to do |format|
        format.json { render json: @measurement, status: :created }
      end
    end
  end

  def respond
    @measurement = find_measurement_for_current_user

    unless @measurement
      respond_to do |format|
        format.html { redirect_to measurements_path, alert: t("flash.measurements.not_found") }
        format.json { render json: { error: t("flash.measurements.not_found") }, status: :not_found }
      end
      return
    end

    if @measurement.responded?
      respond_to do |format|
        format.html { redirect_to measurements_path, alert: t("flash.measurements.already_responded") }
        format.json { render json: { error: t("flash.measurements.already_responded") }, status: :unprocessable_entity }
      end
      return
    end

    if @measurement.mark_as_responded!
      respond_to do |format|
        format.html { redirect_to measurements_path, notice: t("flash.measurements.responded_success") }
        format.json {
          render json: {
            message: t("flash.measurements.responded_success"),
            measurement: @measurement,
            store: @measurement.store
          }, status: :ok
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to measurements_path, alert: t("flash.measurements.respond_failed") }
        format.json { render json: { error: t("flash.measurements.respond_failed") }, status: :unprocessable_entity }
      end
    end
  end

  private

  # def require_company_account
  #   unless Current.user&.is_company
  #     redirect_to root_path, alert: t("flash.measurements.company_only")
  #   end
  # end

  def find_measurement_for_current_user
    if Current.user.is_company
      Measurement
        .where(id: params[:id], store_id: Current.user.operated_stores.select(:id))
        .includes(:store)
        .first
    else
      Measurement.find_by(id: params[:id], submitter_id: Current.user.id)
    end
  end
end
