import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DiscourseURL from "discourse/lib/url";

export default {
  name: "add-trash-button",
  initialize(container) {
    withPluginApi("1.37.1", (api) => {
      const siteSettings = api.container.lookup("site-settings:main");
      const categories =
        siteSettings.discourse_topic_management_categories_remove_button_visible.split(
          "|",
        );
      api.addPostMenuButton("trash", (post) => {
        if (
          siteSettings.discourse_topic_management_hidden_category_id !== "" &&
          categories.includes(post.topic.category_id.toString()) &&
          post.post_number === 1 &&
          post.topicCreatedById === api.getCurrentUser().id
        ) {
          return {
            action: "sendTopicToRecycleBin",
            icon: "box-archive",
            className: "topic-management-button",
            title: "discourse_topic_management.topic.title",
          };
        }
      });

      api.attachWidgetAction("post", "sendTopicToRecycleBin", function () {
        const topicId = this.attrs.topicId;
        const categoryId = this.attrs.topic.category_id;
        this.dialog.yesNoConfirm({
          message: I18n.t("discourse_topic_management.topic.delete_confirm"),
          didConfirm: () => {
            ajax(`/move_topic_to_hidden_category`, {
              method: "POST",
              data: { topic_id: topicId },
            })
              .then(() => {
                DiscourseURL.routeTo(`/c/${categoryId}`);
              })
              .catch((error) => {
                popupAjaxError(error);
              });
          },
        });
      });
    });
  },
};
