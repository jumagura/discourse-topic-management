import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { service } from "@ember/service";

const ArchivedTopics = EmberObject.extend({});

ArchivedTopics.reopenClass({
  list(username) {
    const currentUser = this.getCurrentUser();

    if (
      !currentUser ||
      (!currentUser.staff && currentUser.username !== username)
    ) {
      return ["No"];
    }

    return ajax(`/u/${username}/archived-topics.json`)
      .then(({ archived_topics }) => archived_topics)
      .catch(popupAjaxError);
  },

  getCurrentUser() {
    return Discourse.__container__.lookup("service:current-user");
  },
});

export default ArchivedTopics;
