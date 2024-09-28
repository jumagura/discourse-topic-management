# frozen_string_literal: true

# name: discourse-topic-management
# about: Adds a trash button to move topics to a hidden category
# version: 0.2
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

            # If limit is reached, check if the user is allowed to continue posting
            if unique_repliers.count >= limit &&
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
