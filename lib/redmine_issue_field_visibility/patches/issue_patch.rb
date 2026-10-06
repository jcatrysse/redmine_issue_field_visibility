module RedmineIssueFieldVisibility
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :disabled_core_fields_without_ifv, :disabled_core_fields
          alias_method :disabled_core_fields, :disabled_core_fields_with_ifv
          alias_method :reload_without_ifv, :reload
          alias_method :reload, :reload_with_ifv

          alias_method :total_estimated_hours_without_ifv, :total_estimated_hours
          alias_method :total_estimated_hours, :total_estimated_hours_with_ifv
          if method_defined?(:estimated_remaining_hours)
            alias_method :estimated_remaining_hours_without_ifv, :estimated_remaining_hours
            alias_method :estimated_remaining_hours, :estimated_remaining_hours_with_ifv
          end
          # webhooks, Redmine 7
          if method_defined?(:webhook_payload)
            alias_method :webhook_payload_without_ifv, :webhook_payload
            alias_method :webhook_payload, :webhook_payload_with_ifv
          end

          # Attribute, query (description?) and association readers of the
          # hideable fields answer nil inside RedmineIssueFieldVisibility.hide_values. Rails generates
          # the attribute readers in a module after the plugin is loaded, so
          # they are wrapped from Issue itself through super; a reader that
          # Issue defines itself is aliased instead.
          RedmineIssueFieldVisibility::HIDEABLE_CORE_FIELDS.each do |field|
            readers = [field, "#{field}?"]
            readers << field.sub(/_id\z/, '') if field.end_with?('_id')
            readers.each do |reader|
              if method_defined?(reader, false)
                alias_method "#{reader}_without_ifv", reader
                define_method(reader) do
                  send("#{reader}_without_ifv") unless hidden_core_field_value?(field)
                end
              else
                define_method(reader) do
                  super() unless hidden_core_field_value?(field)
                end
              end
            end
          end
        end
      end
      module InstanceMethods
        def disabled_core_fields_with_ifv
          (disabled_core_fields_without_ifv + hidden_core_fields).tap do |fields|
            fields.uniq!
          end
        end

        def hidden_core_field?(name)
          hidden_core_fields.include?(name.to_s) or
            hidden_core_fields.include?("#{name}_id")
        end

        def hidden_core_fields
          user = @user_for_hidden_core_fields || User.current
          @hidden_core_fields ||= {}
          @hidden_core_fields[[user, project_id]] ||= RedmineIssueFieldVisibility::hidden_core_fields user, project
        end

        def reload_with_ifv(*args)
          reload_without_ifv(*args).tap { @hidden_core_fields = nil }
        end

        def with_hidden_core_fields_for_user(user, &block)
          @user_for_hidden_core_fields = user
          yield
        ensure
          @user_for_hidden_core_fields = nil
        end

        def hidden_core_field_value?(field)
          RedmineIssueFieldVisibility.hide_values? && hidden_core_fields.include?(field)
        end

        def total_estimated_hours_with_ifv
          total_estimated_hours_without_ifv unless hidden_core_field_value?('estimated_hours')
        end

        def estimated_remaining_hours_with_ifv
          estimated_remaining_hours_without_ifv unless hidden_core_field_value?('estimated_hours')
        end

        # The payload is rendered from the issue API template as the webhook
        # user, so it hides what the API hides for that user.
        def webhook_payload_with_ifv(*args)
          RedmineIssueFieldVisibility.hide_values do
            webhook_payload_without_ifv(*args)
          end
        end

        # WARNING: if changed here change in journal_patch too
        def each_notification(users, &block)
          users.group_by do |user|
            if user.admin?
              :admin
            else
              user.roles_for_project(project).sort
            end
          end.values.each do |part|
            super(part, &block)
          end
        end
      end
    end
  end
end

Issue.include(RedmineIssueFieldVisibility::Patches::IssuePatch)
