class MoveTopicController < ApplicationController
  before_action :ensure_logged_in

  def move_to_hidden_category
    topic = Topic.find(params[:topic_id])
    hidden_category_id = SiteSetting.discourse_topic_management_hidden_category_id
    if topic.user_id == current_user.id && topic.category_id != hidden_category_id
      topic.update(category_id: hidden_category_id)
      render json: success_json
    else
      render json: { error: "Unauthorized or already in hidden category" }, status: 403
    end
  end
end
