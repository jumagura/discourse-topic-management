require "rails_helper"

RSpec.describe "Reply Limitation Feature", type: :request do
  fab!(:category) { Fabricate(:category) }
  fab!(:limited_category) { Fabricate(:category) }
  fab!(:topic_owner) { Fabricate(:user) }
  fab!(:staff_user) { Fabricate(:admin) }
  fab!(:regular_user) { Fabricate(:user) }
  fab!(:second_regular_user) { Fabricate(:user) }
  fab!(:third_regular_user) { Fabricate(:user) }
  fab!(:tag) { Fabricate(:tag) }
  fab!(:limited_topic_with_tag) { Fabricate(:topic, user: topic_owner, category: category, tags: [tag]) }
  fab!(:limited_topic_with_category) { Fabricate(:topic, user: topic_owner, category: limited_category) }
  fab!(:non_limited_topic) { Fabricate(:topic, user: topic_owner, category: category) }

  before do
    SiteSetting.discourse_topic_management_enabled = true
    SiteSetting.discourse_topic_management_reply_limit = 3
    SiteSetting.discourse_topic_management_limited_categories = "#{limited_category.id}"
    SiteSetting.discourse_topic_management_limited_tags = tag.name
  end

  context "when the topic is in a limited category" do
    let!(:initial_posts) do
      Fabricate(:post, user: topic_owner, topic: limited_topic_with_category)
      Fabricate(:post, user: regular_user, topic: limited_topic_with_category)
    end

    describe "when reply limit is not yet reached" do
      it "allows all users to reply" do
        sign_in(second_regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_category.id }
        expect(response.status).to eq(200)
        expect(response).to be_successful
      end
    end

    describe "when reply limit is reached" do
      before do
        Fabricate(:post, user: second_regular_user, topic: limited_topic_with_category)
      end

      it "allows the topic owner to reply even after the limit is reached" do
        sign_in(topic_owner)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_category.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it "prevents new users from replying after the limit is reached" do
        sign_in(third_regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_category.id }
        expect(response).not_to be_successful
        expect(response.status).to eq(422)
      end

      it "allows staff to reply regardless of the limit" do
        sign_in(staff_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_category.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end
    end
  end

  context "when the topic has a limited tag" do
    let!(:initial_posts) do
      Fabricate(:post, user: topic_owner, topic: limited_topic_with_tag)
      Fabricate(:post, user: regular_user, topic: limited_topic_with_tag)
    end

    describe "when reply limit is not yet reached" do
      it "allows all users to reply" do
        sign_in(second_regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_tag.id }
        expect(response.status).to eq(200)
        expect(response).to be_successful
      end
    end

    describe "when reply limit is reached" do
      before do
        Fabricate(:post, user: second_regular_user, topic: limited_topic_with_tag)
      end

      it "allows the topic owner to reply even after the limit is reached" do
        sign_in(topic_owner)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_tag.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it "prevents new users from replying after the limit is reached" do
        sign_in(third_regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_tag.id }
        expect(response).not_to be_successful
        expect(response.status).to eq(422)
      end

      it "allows staff to reply regardless of the limit" do
        sign_in(staff_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_tag.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end
    end
  end

  context "when the topic is not in a limited category or does not have limited tags" do
    let!(:initial_posts) do
      Fabricate(:post, user: topic_owner, topic: non_limited_topic)
      Fabricate(:post, user: regular_user, topic: non_limited_topic)
    end

    describe "when reply limit is not applied" do
      it "allows all users to reply without restriction" do
        sign_in(third_regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: non_limited_topic.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end
    end
  end

  context "edge case: topics with existing replies" do
    let!(:pre_existing_posts) do
      3.times { Fabricate(:post, user: Fabricate(:user), topic: limited_topic_with_category) }
    end

    it "still respects the reply limit for new users in limited topics" do
      sign_in(third_regular_user)
      post "/posts.json", params: { raw: "This is a reply", topic_id: limited_topic_with_category.id }
      expect(response).not_to be_successful
      expect(response.status).to eq(422)
    end

    it "allows staff to bypass the limit in limited topics" do
      sign_in(staff_user)
      post "/posts.json", params: { raw: "This is a staff reply", topic_id: limited_topic_with_category.id }
      expect(response).to be_successful
      expect(response.status).to eq(200)
    end
  end
  context "edge case: applying limited tag after reply limit is reached" do
    let!(:initial_posts) do
      Fabricate(:post, user: topic_owner, topic: non_limited_topic)
      Fabricate(:post, user: regular_user, topic: non_limited_topic)
    end

    before do
      Fabricate(:post, user: second_regular_user, topic: non_limited_topic)
    end

    it "prevents new users from replying after the limited tag is added" do
      non_limited_topic.tags << tag

      sign_in(third_regular_user)
      post "/posts.json", params: { raw: "This is a reply", topic_id: non_limited_topic.id }
      expect(response).not_to be_successful
      expect(response.status).to eq(422)
    end

    it "allows the topic owner to reply after the limited tag is added" do
      non_limited_topic.tags << tag

      sign_in(topic_owner)
      post "/posts.json", params: { raw: "This is a reply", topic_id: non_limited_topic.id }
      expect(response).to be_successful
      expect(response.status).to eq(200)
    end

    it "allows existing repliers to reply after the limited tag is added" do
      non_limited_topic.tags << tag

      sign_in(regular_user)
      post "/posts.json", params: { raw: "This is a reply", topic_id: non_limited_topic.id }
      expect(response).to be_successful
      expect(response.status).to eq(200)
    end

    it "allows staff to reply after the limited tag is added" do
      non_limited_topic.tags << tag

      sign_in(staff_user)
      post "/posts.json", params: { raw: "This is a staff reply", topic_id: non_limited_topic.id }
      expect(response).to be_successful
      expect(response.status).to eq(200)
    end
  end
end
