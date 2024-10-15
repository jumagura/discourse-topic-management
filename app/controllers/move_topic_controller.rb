class MoveTopicController < ApplicationController
  before_action :ensure_logged_in

  def move_to_hidden_category
    topic = Topic.find(params[:topic_id])
    hidden_category_id = SiteSetting.discourse_topic_management_hidden_category_id
    category = Category.find(hidden_category_id)
    user_allowed = current_user.staff? || topic.user_id == current_user.id
    if user_allowed && topic.category_id != hidden_category_id
      begin
        topic.update!(category: category)
      rescue StandardError => e
        Rails.logger.error(e)
      end
      render json: success_json
    else
      render json: { error: "Unauthorized or already in hidden category" }, status: 403
    end
  end
end
