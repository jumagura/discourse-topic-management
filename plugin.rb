# frozen_string_literal: true

# name: discourse-topic-management
# about: Adds features for managing topics: Move topics to a hidden category and limit replies based on unique repliers, categories, or tags.
# version: 0.3
# authors: Marcos Gutierrez
# url: https://github.com/your-repo/discourse-topic-management

enabled_site_setting :discourse_topic_management_enabled

after_initialize do
  load File.expand_path("../app/controllers/move_topic_controller.rb", __FILE__)

  Discourse::Application.routes.append do
    post "/move_topic_to_hidden_category" => "move_topic#move_to_hidden_category"
  end

  module DiscourseTopicManagement
    module PostGuardianExtension
      extend ActiveSupport::Concern

      prepended do
        alias_method :existing_can_create_post_in_topic?, :can_create_post_in_topic?

        def can_create_post_in_topic?(topic)
          if SiteSetting.discourse_topic_management_reply_limit.present? && topic
            unique_repliers = topic.posts.pluck(:user_id)
            limit = SiteSetting.discourse_topic_management_reply_limit.to_i
            limited_categories = SiteSetting.discourse_topic_management_limited_categories.split("|").map(&:to_i)
            limited_tags = SiteSetting.discourse_topic_management_limited_tags.split("|")

            # Check if the topic is in a limited category or has limited tags
            if (limited_categories.include?(topic.category_id) || (limited_tags & topic.tags.map(&:name)).present?) &&
               unique_repliers.count >= limit &&
               !user.staff? && # Allow staff
               !unique_repliers.include?(user.id) # Allow original poster and existing repliers
              return false # Block any new repliers
            end
          end

          existing_can_create_post_in_topic?(topic)
        end
      end
    end
  end

  PostGuardian.prepend(DiscourseTopicManagement::PostGuardianExtension)
end
