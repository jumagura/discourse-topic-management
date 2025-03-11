export default {
  resource: "user",
  map() {
    this.route("archived-topics", { resetNamespace: true });
  },
};
