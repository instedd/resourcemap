ActiveSupport.on_load(:active_record) do
  module AuthCopScope
    extend ActiveSupport::Concern

    module ClassMethods
      def inherited(child)
        child.instance_eval do
          # auth_scope_for(:ability) { |ability| accessible_by(ability).readonly(false) }
          auth_scope_for(:user) { |user| AuthCop.unsafe { Pundit.policy_scope!(user, child) } }
          # before_create { authcop_authorize!(:create) }
        end
        super
      end
    end

    def delete
      if user = AuthCop.current_user
        raise "not authorized to delete #{self}" unless Pundit.policy!(user, self).destroy?
        AuthCop.unsafe { super }
      else
        super
      end
    end

    def destroy
      if user = AuthCop.current_user
        raise "not authorized to delete #{self}" unless Pundit.policy!(user, self).destroy?
        AuthCop.unsafe { super }
      else
        super
      end
    end
  end

  class ActiveRecord::Base
    include AuthCopScope

    def authcop_authorize!(action)
      return if AuthCop.unsafe?
      if (scope = AuthCop.current_scope).is_a?(Ability)
        AuthCop.unsafe do
          scope.authorize!(action, self)
        end
      end
    end
  end
end

module AuthCop
  def self.current_user
    case scope = AuthCop.current_scope
    when Ability then scope.user
    when User then scope
    end
  end
end
