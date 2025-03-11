import { withPluginApi } from "discourse/lib/plugin-api";
export default {
  shouldRender(args, component) {
    const hidden_category =
      component.siteSettings.discourse_topic_management_hidden_category_id;
    const currentUser = withPluginApi("1.2.0", (api) => {
      return api.getCurrentUser();
    });
    const userAllowed =
      currentUser.admin ||
      currentUser.moderator ||
      args.topic.user_id === currentUser.id;

    return args.topic.category_id.toString() == hidden_category && userAllowed;
  },
};
