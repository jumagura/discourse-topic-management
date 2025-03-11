# frozen_string_literal: true
module ::DiscourseTopicManagement
  class Engine < ::Rails::Engine
    engine_name "discourse_topic_management"
    isolate_namespace DiscourseTopicManagement
  end

  PLUGIN_NAME ||= "discourse_topic_management"
end
