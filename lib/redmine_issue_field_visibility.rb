module RedmineIssueFieldVisibility

  # done_ratio makes trouble if nil'd in issue patch (validation, calculation)
  # parent_issue_id doesn't make much sense
  HIDEABLE_CORE_FIELDS = Tracker::CORE_FIELDS - %w(done_ratio parent_issue_id)

  # Inside the block the issue readers of the core fields hidden for the
  # current user answer nil. Used while issue data is rendered for a user (API
  # responses, webhook payloads), not around Redmine's own calculations, which
  # need the real values.
  def self.hide_values
    hiding = Thread.current[:redmine_issue_field_visibility_hide_values]
    Thread.current[:redmine_issue_field_visibility_hide_values] = true
    yield
  ensure
    Thread.current[:redmine_issue_field_visibility_hide_values] = hiding
  end

  def self.hide_values?
    Thread.current[:redmine_issue_field_visibility_hide_values] == true
  end

  def self.hidden_core_fields(user = User.current, project = nil)
    return [] if user.admin?
    if (fields_by_role = Setting.plugin_redmine_issue_field_visibility['hiddenfields'])
      roles = if project
        user.roles_for_project(project)
      else
        user.memberships.map(&:roles).flatten.uniq
      end

      # get the list of hidden fields for each role
      hidden_field_lists = roles.map do |role|
        if (hidden_fields = fields_by_role[role.id.to_s])
          hidden_fields.map do |field_name, value|
            field_name if value.to_s == '1'
          end
        else
          []
        end.compact
      end

      # we now have the lists of hidden fields per role. the intersection of
      # these is the list of fields to hide
      result = hidden_field_lists.shift
      hidden_field_lists.each do |list|
        result &= list
      end

      result || []
    else
      []
    end
  end
end
