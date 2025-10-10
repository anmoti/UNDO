class MeasurementsController < ApplicationController
  layout "main"

  def index
    if Current.user.is_company
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
    else
      @measurements = Measurement.where(submitter_id: Current.user.id)
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
    @measurement.submitter = Current.user

    # 企業アカウントの場合はstore_idが必須
    if Current.user.is_company && !permitted_params[:store_id].present?
      return render json: { error: "企業アカウントの場合、店舗IDが必要です" }, status: :unprocessable_entity
    end

    # 一般ユーザーの場合はstore_idを設定しない
    if !Current.user.is_company
      @measurement.store_id = nil
    end

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
  end

  def respond
    @measurement = find_measurement_for_current_user

    unless @measurement
      respond_to do |format|
        format.html { redirect_to measurements_path, alert: "測定データが見つかりません" }
        format.json { render json: { error: "測定データが見つかりません" }, status: :not_found }
      end
      return
    end

    if @measurement.responded?
      respond_to do |format|
        format.html { redirect_to measurements_path, alert: "既に対応済みです" }
        format.json { render json: { error: "既に対応済みです" }, status: :unprocessable_entity }
      end
      return
    end

    if @measurement.mark_as_responded!
      respond_to do |format|
        format.html { redirect_to measurements_path, notice: "対応完了しました。エコマークが付与されました。" }
        format.json {
          render json: {
            message: "対応完了しました。エコマークが付与されました。",
            measurement: @measurement,
            store: @measurement.store
          }, status: :ok
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to measurements_path, alert: "対応処理に失敗しました" }
        format.json { render json: { error: "対応処理に失敗しました" }, status: :unprocessable_entity }
      end
    end
  end

  private

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
