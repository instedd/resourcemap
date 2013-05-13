require 'spec_helper'
require "cancan/matchers"

describe Ability do

	describe "Collection Abilities" do
		let!(:admin) { User.make }
		let!(:user) { User.make }
		let!(:member) { User.make }
		let!(:collection) { admin.create_collection Collection.make }
		let!(:membership) { collection.memberships.create! :user_id => member.id }

		let!(:admin_ability) { Ability.new(admin)}
		let!(:member_ability) { Ability.new(member)}
		let!(:user_ability) { Ability.new(user)}


		describe "Destroy collection" do
			it { admin_ability.should be_able_to(:destroy, collection) }
			it { member_ability.should_not be_able_to(:destroy, collection) }
			it { user_ability.should_not be_able_to(:destroy, collection) }
		end

		describe "Create snapshot" do
			it { admin_ability.should be_able_to(:create_snapshot, collection) }
			it { member_ability.should_not be_able_to(:create_snapshot, collection) }
			it { user_ability.should_not be_able_to(:create_snapshot, collection) }
		end

		describe "Update collection" do 
			it { admin_ability.should be_able_to(:update, collection) }
			it { member_ability.should_not be_able_to(:upate, collection) }
			it { user_ability.should_not be_able_to(:update, collection) }
		end

		describe "Public Collection Abilities" do
			let!(:public_collection) { admin.create_collection Collection.make public: true}

			it { user_ability.should_not be_able_to(:read, collection) }
			
		end
	end

end