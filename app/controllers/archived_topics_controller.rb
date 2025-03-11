# frozen_string_literal: true

class ArchivedTopicsController < ::ApplicationController
  requires_plugin DiscourseTopicManagement::PLUGIN_NAME
  before_action :ensure_logged_in, :set_view_path

  def index
    user = fetch_user
    return render json: { errors: [I18n.t("follow.user_not_found", username: params[:username].inspect)] }, status: 404 if user.nil?

    render_serialized(user.as_json(only: [:id, :email]), DiscourseTopicManagement::ArchivedTopicsSerializer)
  end

  private

  def set_view_path
    append_view_path "plugins/discourse-topic-management/views"
  end

  def fetch_user
    user = User.find_by_username(params.require(:username))

    # Ensure only the same user or a staff member can fetch the data
    return nil if user.blank? || (!guardian.is_staff? && guardian.user != user)

    user
  end
end
