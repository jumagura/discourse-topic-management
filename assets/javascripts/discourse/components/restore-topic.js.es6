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
    restoreTopic() {
      const topic = this.topic;
      const topicId = topic.id;
      this.dialog.yesNoConfirm({
        message: I18n.t("discourse_topic_management.topic.restore_confirm"),
        didConfirm: () => {
          ajax(`/restore_topic_to_previous_category`, {
            method: "POST",
            data: { topic_id: topicId },
          })
            .then(() => {
              DiscourseURL.routeTo(`/t/${topicId}`);
            })
            .catch((error) => {
              popupAjaxError(error);
            });
        },
      });
    },
  },
});
