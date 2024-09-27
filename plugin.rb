# frozen_string_literal: true

# name: discourse-topic-management
# about: Adds a trash button to move topics to a hidden category
# version: 0.1
# authors: Marcos Gutierrez
# url: https://github.com/your-repo/discourse-topic-management

enabled_site_setting :discourse_topic_management_enabled

after_initialize do
  load File.expand_path("../app/controllers/move_topic_controller.rb", __FILE__)

  Discourse::Application.routes.append do
    post "/move_topic_to_hidden_category" => "move_topic#move_to_hidden_category"
  end
end
