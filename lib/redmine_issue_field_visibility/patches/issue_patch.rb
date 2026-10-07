module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    module IssuePatch
      # Attribute, query (description?) and association readers of the
      # hideable fields answer nil inside RedmineIssueFieldVisibility.hide_values.
      # Being prepended, they wrap the readers Rails generates after the plugin
      # is loaded as well as the ones Issue defines itself.
      RedmineIssueFieldVisibility::HIDEABLE_CORE_FIELDS.each do |field|
        readers = [field, "#{field}?"]
        readers << field.sub(/_id\z/, '') if field.end_with?('_id')
        readers.each do |reader|
          define_method(reader) do
            super() unless hidden_core_field_value?(field)
          end
        end
      end

      def disabled_core_fields
        (super + hidden_core_fields).tap do |fields|
          fields.uniq!
        end
      end

      def hidden_core_field?(name)
        hidden_core_fields.include?(name.to_s) or
          hidden_core_fields.include?("#{name}_id")
      end

      # Cached per user and project. Issue#reload is not patched to clear the
      # cache: the redmineup gem (redmineup_tags) sets up an alias_method chain
      # on it after this plugin is loaded, which recurses into a prepended
      # reload. A reload does not change the settings or the user's roles; a
      # changed project gets its own cache entry.
      def hidden_core_fields
        user = @user_for_hidden_core_fields || User.current
        @hidden_core_fields ||= {}
        @hidden_core_fields[[user, project_id]] ||= RedmineIssueFieldVisibility::hidden_core_fields user, project
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

      def total_estimated_hours
        super unless hidden_core_field_value?('estimated_hours')
      end

      def estimated_remaining_hours
        super unless hidden_core_field_value?('estimated_hours')
      end

      # webhooks, Redmine 7. The payload is rendered from the issue API
      # template as the webhook user, so it hides what the API hides for that
      # user.
      def webhook_payload(*args)
        RedmineIssueFieldVisibility.hide_values do
          super
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

Issue.prepend(RedmineIssueFieldVisibility::Patches::IssuePatch)
