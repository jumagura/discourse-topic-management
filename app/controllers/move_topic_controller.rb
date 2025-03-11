class MoveTopicController < ApplicationController
  before_action :ensure_logged_in

  def move_to_hidden_category
    topic = Topic.find(params[:topic_id])
    previous_category_id = topic.category_id
    hidden_category_id = SiteSetting.discourse_topic_management_hidden_category_id
    category = Category.find(hidden_category_id)
    user_allowed = current_user.staff? || topic.user_id == current_user.id
    if user_allowed && topic.category_id != hidden_category_id
      begin
        topic.update!(category: category)
        topic_custom_field = TopicCustomField.find_or_initialize_by(topic_id: topic.id, name: "previous_category_id")
        topic_custom_field.value = previous_category_id
        topic_custom_field.save!
      rescue StandardError => e
        Rails.logger.error(e)
      end
      render json: success_json
    else
      render json: { error: I18n.t("discourse_topic_management.archive_not_posible") }, status: 403
    end
  end

  def restore_to_previous_category
    topic = Topic.find(params[:topic_id])
    previous_category = TopicCustomField.find_by(topic_id: topic.id, name: "previous_category_id")
    hidden_category_id = SiteSetting.discourse_topic_management_hidden_category_id.to_i
    user_allowed = current_user.staff? || topic.user_id == current_user.id
    if user_allowed && topic.category_id == hidden_category_id && !previous_category.nil?
      begin
        if topic.update(category_id: previous_category.value.to_i)
          puts "Update successful!"
        else
          puts "Update failed: #{topic.errors.full_messages.join(", ")}"
        end
      rescue StandardError => e
        Rails.logger.error(e)
      end
      render json: success_json
    else
      render json: { error: I18n.t("discourse_topic_management.restore_not_posible") }, status: 403
    end
  end
end
