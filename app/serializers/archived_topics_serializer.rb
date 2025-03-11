# frozen_string_literal: true

class DiscourseTopicManagement::ArchivedTopicsSerializer < ApplicationSerializer
  attributes :archived_topics

  def archived_topics
    category_id = SiteSetting.discourse_topic_management_hidden_category_id.to_i
    Topic.where(user_id: object["id"].to_i).where(category_id: category_id).pluck(:id, :title, :excerpt, :fancy_title, :created_at, :slug)
  end
end
