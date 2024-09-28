# frozen_string_literal: true

# name: discourse-topic-management
# about: Adds features for managing topics: Move topics to a hidden category and limit replies based on unique repliers, categories, or tags.
# version: 0.3.1
# authors: Marcos Gutierrez
# contact_emails: jumagura@pavilion.tech
# url: https://github.com/jumagura/discourse-topic-management

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
          if SiteSetting.discourse_topic_management_enabled && topic
            unique_repliers = topic.posts.pluck(:user_id)

            # Parsing category limits
            category_limits = SiteSetting.discourse_topic_management_category_limits.split("|").map { |pair| pair.split(":") }.to_h
            category_limit = category_limits[topic.category_id.to_s].to_i if category_limits[topic.category_id.to_s]

            # Parsing tag limits
            tag_limits = SiteSetting.discourse_topic_management_tag_limits.split("|").map { |pair| pair.split(":") }.to_h
            tag_limit = nil
            topic.tags.each do |tag|
              tag_limit = tag_limits[tag.name].to_i if tag_limits[tag.name]
              break if tag_limit
            end

            # The actual limit will be determined by category or tag-specific settings
            limit = tag_limit || category_limit

            # Skip reply limitation if no limit is set for the category or tag
            if limit && unique_repliers.count >= limit && !user.staff? && !unique_repliers.include?(user.id)
              return false # Block new repliers if the limit is reached
            end
          end
          # Fallback to the original Guardian behavior
          existing_can_create_post_in_topic?(topic)
        end
      end
    end
  end

  PostGuardian.prepend(DiscourseTopicManagement::PostGuardianExtension)
end
