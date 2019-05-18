class FeedbacksController < ApplicationController
  
  def index
    @feedbacks = Feedback.where(company_token: params[:company_token])
    render json: @feedbacks
  rescue StandardError => e
    render json: {message: e.message}, status: :bad_request
  end

  def show
    @feedback = Feedback.find_by!(company_token: params[:company_token], number: params[:number])
      render json: @feedback, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { id: "Could not find" }, status: :not_found
  end

  def create
    @feedback = Feedback.new(feedback_params)
    @feedback.state = State.new(state_params)
    if @feedback.valid?
      @feedback.number = $redis.incr("#{@feedback.company_token}_feedbacks_count")
      FeedbackCreatorWorker.perform_async(feedback_creation_params,state_params)
      render json: { number: @feedback.number }, status: :created
    else
      render json: @feedback.errors, status: :unprocessable_entity
    end
  end

  def count
    @feeback_count = Feedback.where(company_token: params[:company_token]).count
    render json: @feeback_count
  end

  private 

  def feedback_creation_params
    feedback_params.merge(number: @feedback.number)
  end

  def feedback_params
    params.permit(:company_token, :number, :priority )
  end

  def state_params
    params.require(:state).permit(:device, :os, :memory, :storage)
  end
end
