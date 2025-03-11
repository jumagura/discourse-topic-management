import Controller from "@ember/controller";

export default Controller.extend({
  archivedTopics: null,

  init() {
    this._super(...arguments);
  },
});
