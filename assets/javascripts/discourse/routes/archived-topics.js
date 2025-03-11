import DiscourseRoute from "discourse/routes/discourse";
import { all } from "rsvp";
import ArchivedTopics from "../models/archived-topics";

export default DiscourseRoute.extend({
  model() {
    if (!this.currentUser) {
      return { error: "not_logged_in" };
    }
    const user = this.modelFor("user");
    const settings = this.siteSettings;
    return all([ArchivedTopics.list(user.username)]);
  },

  setupController(controller, model) {
    if (model.error) {
      controller.setProperties({
        error: model.error,
      });
    } else {
      console.log(typeof model[0]);

      controller.setProperties({
        archivedTopics: model[0],
      });
    }
  },

  actions: {
    refreshRoute() {
      this.refresh();
    },
  },
});
