require File.expand_path('../../test_helper', __FILE__)

# Other plugins (redmine_agile, redmine_contacts_helpdesk, redmine_itil_priority,
# ...) prepend modules on the same core methods. An alias_method chain set up
# after such a prepend aliases the prepended method and recurses
# (SystemStackError on every issue query with redmine_agile installed), so every
# patch of this plugin is prepended.
class PatchesPrependedTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :trackers, :issues,
           :projects_trackers, :enabled_modules, :issue_statuses, :enumerations

  PATCHES = {
    ApplicationController => [RedmineIssueFieldVisibility::Patches::ApplicationControllerPatch, %i(render_to_body)],
    Issue => [RedmineIssueFieldVisibility::Patches::IssuePatch,
              %i(disabled_core_fields total_estimated_hours estimated_remaining_hours webhook_payload
                 assigned_to assigned_to_id description estimated_hours start_date priority)],
    IssueQuery => [RedmineIssueFieldVisibility::Patches::IssueQueryPatch, %i(initialize_available_filters available_columns)],
    IssuesHelper => [RedmineIssueFieldVisibility::Patches::IssuesHelperPatch, %i(email_issue_attributes)],
    Journal => [RedmineIssueFieldVisibility::Patches::JournalPatch, %i(visible_details)],
    Mailer => [RedmineIssueFieldVisibility::Patches::MailerPatch, %i(issue_add issue_edit)],
    QueriesHelper => [RedmineIssueFieldVisibility::Patches::QueriesHelperPatch, %i(column_content)],
    Version => [RedmineIssueFieldVisibility::Patches::VersionPatch, %i(estimated_hours estimated_remaining_hours visible_fixed_issues)],
  }

  PATCHES.each do |base, (patch, methods)|
    test "#{patch.name.demodulize} is prepended to #{base}" do
      ancestors = base.ancestors
      assert_includes ancestors, patch
      assert_operator ancestors.index(patch), :<, ancestors.index(base),
                      "#{patch} must be prepended, not included"
      defined = patch.instance_methods(false) + patch.private_instance_methods(false)
      methods.each do |m|
        assert_includes defined, m, "#{patch} must define #{base}##{m}"
      end
    end

    test "#{base} has no alias_method chain of this plugin" do
      defined = base.instance_methods + base.private_instance_methods
      chained = methods.flat_map { |m| [:"#{m}_with_ifv", :"#{m}_without_ifv"] } & defined
      assert_empty chained
    end
  end

  test "a module another plugin prepends composes with the issue query patch" do
    other = Module.new do
      def available_columns
        super.tap { @other_plugin_columns_called = true }
      end

      def initialize_available_filters
        super
        @other_plugin_filters_called = true
      end
    end
    IssueQuery.prepend(other)

    User.current = User.find(2)
    with_settings(plugin_redmine_issue_field_visibility: {
      'hiddenfields' => { '1' => { 'estimated_hours' => '1' } }
    }) do
      query = IssueQuery.new(project: Project.find(1))
      names = query.available_columns.map(&:name)
      assert_not_includes names, :estimated_hours
      assert_not_includes names, :estimated_remaining_hours
      assert_includes names, :subject
      assert_nil query.available_filters['estimated_hours']
      assert query.instance_variable_get(:@other_plugin_columns_called)
      assert query.instance_variable_get(:@other_plugin_filters_called)
    end
  end

  # The redmineup gem (acts_as_taggable, called on Issue by redmineup_tags,
  # which loads after this plugin) aliases Issue#reload in Issue itself.
  test "Issue#reload survives an alias_method chain set up after the plugin" do
    own = Issue.instance_method(:reload)
    own = own.super_method until own.owner == Issue
    Issue.class_eval do
      alias_method :reload_without_tag_list_test, :reload
      define_method(:reload) { |*args| reload_without_tag_list_test(*args) }
    end
    issue = Issue.find(1)
    assert_nothing_raised { assert_equal issue, issue.reload }
  ensure
    Issue.class_eval do
      define_method(:reload, own)
      remove_method :reload_without_tag_list_test
    end
  end
end
