require "rails_helper"

RSpec.describe "Reply Limitation Feature", type: :request do
  fab!(:category) { Fabricate(:category) }
  fab!(:topic_owner) { Fabricate(:user) }
  fab!(:staff_user) { Fabricate(:admin) }
  fab!(:regular_user) { Fabricate(:user) }
  fab!(:second_regular_user) { Fabricate(:user) }
  fab!(:third_regular_user) { Fabricate(:user) }
  fab!(:topic) { Fabricate(:topic, user: topic_owner, category: category) }

  before do
    SiteSetting.discourse_topic_management_enabled = true
    SiteSetting.discourse_topic_management_reply_limit = 3
  end

  context "when setting up topic with different unique repliers" do
    let!(:initial_posts) do
      Fabricate(:post, user: topic_owner, topic: topic)
      Fabricate(:post, user: regular_user, topic: topic)
    end

    describe "when reply limit is not yet reached" do
      it "allows all users to reply" do
        sign_in(second_regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: topic.id }
        expect(response.status).to eq(200)
        expect(response).to be_successful
      end
    end

    describe "when reply limit is reached" do
      before do
        Fabricate(:post, user: second_regular_user, topic: topic)
      end

      it "allows the topic owner to reply even after the limit is reached" do
        sign_in(topic_owner)
        post "/posts.json", params: { raw: "This is a reply", topic_id: topic.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it "allows existing repliers to reply even after the limit is reached" do
        sign_in(regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: topic.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end

      it "prevents new users from replying after the limit is reached" do
        sign_in(third_regular_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: topic.id }
        expect(response).not_to be_successful
        expect(response.status).to eq(422)
      end

      it "allows staff to reply regardless of the limit" do
        sign_in(staff_user)
        post "/posts.json", params: { raw: "This is a reply", topic_id: topic.id }
        expect(response).to be_successful
        expect(response.status).to eq(200)
      end
    end
  end

  context "edge case: topics with existing replies" do
    let!(:pre_existing_posts) do
      3.times { Fabricate(:post, user: Fabricate(:user), topic: topic) }
    end

    it "still respects the reply limit for new users" do
      sign_in(third_regular_user)
      post "/posts.json", params: { raw: "This is regular user reply", topic_id: topic.id }
      expect(response).not_to be_successful
      expect(response.status).to eq(422)
    end

    it "allows staff to bypass the limit" do
      sign_in(staff_user)
      post "/posts.json", params: { raw: "This is a staff reply", topic_id: topic.id }
      expect(response).to be_successful
      expect(response.status).to eq(200)
    end
  end
end
