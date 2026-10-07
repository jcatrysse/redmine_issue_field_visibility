module RedmineIssueFieldVisibility
  module Patches
    # Prepended, see ApplicationControllerPatch.
    module IssuesHelperPatch
      TOOLTIP_FIELDS = %w(start_date due_date assigned_to_id priority_id)

      def email_issue_attributes(issue, user, *_)
        issue.with_hidden_core_fields_for_user(user) do
          super
        end
      end

      # The tooltip of an issue in the gantt chart and the calendar leaves out
      # the lines of the fields hidden for the user. Same markup as core
      # IssuesHelper#render_issue_tooltip (Redmine 7.0), which is called
      # unchanged when none of its fields is hidden.
      def render_issue_tooltip(issue)
        hidden = TOOLTIP_FIELDS & issue.hidden_core_fields
        return super if hidden.empty?

        lines = [
          "<strong>#{l(:field_project)}</strong>: #{link_to_project(issue.project)}".html_safe,
          "<strong>#{l(:field_status)}</strong>: #{h(issue.status.name) + (" (#{format_date(issue.closed_on)})" if issue.closed?)}".html_safe
        ]
        unless hidden.include?('start_date')
          lines << "<strong>#{l(:field_start_date)}</strong>: #{format_date(issue.start_date)}".html_safe
        end
        unless hidden.include?('due_date')
          lines << "<strong>#{l(:field_due_date)}</strong>: #{format_date(issue.due_date)}".html_safe
        end
        unless hidden.include?('assigned_to_id')
          lines << "<strong>#{l(:field_assigned_to)}</strong>: #{avatar(issue.assigned_to, :size => '13', :title => l(:field_assigned_to)) if issue.assigned_to} #{h(issue.assigned_to)}".html_safe
        end
        unless hidden.include?('priority_id')
          lines << "<strong>#{l(:field_priority)}</strong>: #{h(issue.priority.name)}".html_safe
        end
        link_to_issue(issue) + "<br /><br />".html_safe + safe_join(lines, "<br />".html_safe)
      end
    end
  end
end

IssuesHelper.prepend(RedmineIssueFieldVisibility::Patches::IssuesHelperPatch)
