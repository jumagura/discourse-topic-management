import { withPluginApi } from "discourse/lib/plugin-api";
export default {
  shouldRender(args, component) {
    const categories =
      component.siteSettings.discourse_topic_management_categories_remove_button_visible.split(
        "|",
      );

    const destination_category =
      component.siteSettings.discourse_topic_management_hidden_category_id;
    const currentUser = withPluginApi("1.2.0", (api) => {
      return api.getCurrentUser();
    });
    const userAllowed =
      currentUser.admin ||
      currentUser.moderator ||
      args.topic.user_id === currentUser.id;

    return (
      destination_category !== "" &&
      categories.includes(args.topic.category_id.toString()) &&
      userAllowed
    );
  },
};
