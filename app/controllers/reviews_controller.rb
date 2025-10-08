class ReviewsController < ApplicationController
  layout "main", only: [ :new ]
  allow_unauthenticated_access only: %i[index show]
  before_action :set_review, only: %i[ show edit update destroy ]
  before_action :check_company_account, only: %i[ new create ]

  # GET /reviews or /reviews.json
  def index
    @reviews = Review.all

    # reviewee_idでフィルタリング
    if params[:reviewee_id].present?
      @reviews = @reviews.where(reviewee_id: params[:reviewee_id])
    end

    respond_to do |format|
      format.html
      format.json { render json: @reviews }
    end
  end

  # GET /reviews/1 or /reviews/1.json
  def show
  end

  # GET /reviews/new
  def new
    @review = Review.new
    @review.reviewer_id = Current.user.id

    # URLパラメータからreviewee_idを設定
    if params[:reviewee_id].present?
      @review.reviewee_id = params[:reviewee_id]
      @store = Store.find_by(id: params[:reviewee_id])
    end
  end

  # GET /reviews/1/edit
  def edit
  end

  # POST /reviews or /reviews.json
  def create
    @review = Review.new(review_params)

    respond_to do |format|
      if @review.save
        format.html { redirect_to root_path, notice: "レビューを投稿しました。" }
        format.json { render :show, status: :created, location: @review }
      else
        format.html do
          # エラーがある場合、reviewee_idから店舗情報を取得して表示
          if @review.reviewee_id.present?
            @store = Store.find_by(id: @review.reviewee_id)
          end
          render :new, status: :unprocessable_entity
        end
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reviews/1 or /reviews/1.json
  def update
    respond_to do |format|
      if @review.update(review_params)
        format.html { redirect_to @review, notice: "Review was successfully updated." }
        format.json { render :show, status: :ok, location: @review }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reviews/1 or /reviews/1.json
  def destroy
    @review.destroy!

    respond_to do |format|
      format.html { redirect_to reviews_path, status: :see_other, notice: "Review was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_review
      @review = Review.find(params[:id])
    end

    # 企業アカウントがレビューを投稿できないようにチェック
    def check_company_account
      if Current.user&.is_company?
        redirect_to root_path, alert: "企業アカウントはレビューを投稿できません。"
      end
    end

    # 信頼できるパラメーターのリストだけを通す。
    def review_params
      # review keyとpermit属性が必要。reviewer_idがフォームから提供されない場合、デフォルトは現在サインインしているユーザーのidとなる。
      permitted = params.require(:review).permit(:reviewer_id, :reviewee_id, :comment, :rating)
      permitted[:reviewer_id] = Current.user.id if permitted[:reviewer_id].blank? && defined?(Current) && Current.user
      permitted
    end
end
