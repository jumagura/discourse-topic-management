import Component from "@ember/component";
import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";

export default Component.extend({
  dialog: service(),
  tagName: "span",

  actions: {
    removeTopic() {
      const topic = this.topic;
      const topicId = topic.id;
      const categoryId = topic.category_id;
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
    },
  },
});
