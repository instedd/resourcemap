class ApplicationPolicy
  attr_reader :user, :record
  include PolicyHelper

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def read?
    show?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  def t
    record.class.arel_table
  end

  class Scope
    attr_reader :user, :scope
    include PolicyHelper

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def t
      scope.arel_table
    end

    def member_collections
      Membership.where(user_id: user).pluck(:collection_id)
    end

    def resolve
      scope.where("1=0")
    end
  end

  def self.inherited(child)
    child.class_eval %(class Scope < #{child.superclass::Scope.name}; end)
  end

end

