# frozen_string_literal: true

# name: discourse-topic-management
# about: Adds features for managing topics: Move topics to a hidden category and limit replies based on unique repliers, categories, or tags.
# version: 0.4.1
# authors: Marcos Gutierrez
# contact_emails: jumagura@pavilion.tech
# url: https://github.com/jumagura/discourse-topic-management

enabled_site_setting :discourse_topic_management_enabled

after_initialize do
  %w[
    ../lib/engine.rb
    ../app/controllers/move_topic_controller.rb
    ../app/controllers/archived_topics_controller.rb
    ../app/serializers/archived_topics_serializer.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  Discourse::Application.routes.append do
    post "/move_topic_to_hidden_category" => "move_topic#move_to_hidden_category"
    post "/restore_topic_to_previous_category" => "move_topic#restore_to_previous_category"
    get "/u/:username/archived-topics" => "archived_topics#index", constraints: { username: RouteFormat.username }
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

  module TopicTitleLimitReachedNotification
    def limit_reached
      unique_repliers = topic.posts.pluck(:user_id)
      category_limits = SiteSetting.discourse_topic_management_category_limits.split("|").map { |pair| pair.split(":") }.to_h
      category_limit = category_limits[topic.category_id.to_s].to_i if category_limits[topic.category_id.to_s]

      # Parsing tag limits
      tag_limits = SiteSetting.discourse_topic_management_tag_limits.split("|").map { |pair| pair.split(":") }.to_h
      tag_limit = nil
      topic.tags.each do |tag|
        tag_limit = tag_limits[tag.name].to_i if tag_limits[tag.name]
        break if tag_limit
      end
      limit = tag_limit || category_limit
      user = self&.scope&.user
      return false if !user
      if limit && unique_repliers.count - 1 >= limit && !user.staff? && !unique_repliers.include?(user.id)
        return true
      end
      false
    end
  end

  class ::TopicListItemSerializer
    prepend TopicTitleLimitReachedNotification
    attributes :limit_reached
  end

  class ::TopicViewSerializer
    prepend TopicTitleLimitReachedNotification
    attributes :limit_reached
  end

  module TopicManagementTopicGuardianExtension
    def can_see_topic?(topic, hide_deleted = true)
      hidden_category_id = SiteSetting.discourse_topic_management_hidden_category_id.to_i
      # Allow user to see unlisted topics if they own the topic and it's in the hidden category
      if topic&.category_id == hidden_category_id && topic&.user_id == @user&.id
        return true
      end
      super
    end
  end

  Guardian.prepend TopicManagementTopicGuardianExtension
end
