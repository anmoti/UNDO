class ReviewsController < ApplicationController
  layout "main", only: [ :new ]
  before_action :check_company_account, only: %i[ new create ]

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

  # POST /reviews or /reviews.json
  def create
    @review = Current.user.written_reviews.build(review_params)

    respond_to do |format|
      if @review.save
        format.html { redirect_to root_path, notice: t("flash.reviews.created") }
        format.json { render :show, status: :created, location: @review }
      else
        @store = Store.find(params[:review][:reviewee_id])
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  # 企業アカウントがレビューを投稿できないようにチェック
  def check_company_account
    if Current.user&.is_company?
      redirect_to root_path, alert: t("flash.reviews.company_restriction")
    end
  end
    # Strong parametersで許可するパラメーターを定義
    def review_params
      permitted = params.require(:review).permit(:reviewer_id, :reviewee_id, :comment, :rating)
      # reviewer_idが提供されない場合、現在ログインしているユーザーをデフォルトとして設定
      permitted[:reviewer_id] = Current.user.id if permitted[:reviewer_id].blank? && Current.user
      permitted
    end
end
