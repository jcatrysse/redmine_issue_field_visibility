require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# redmine_view_issue_description, when installed next to this plugin, makes its
# permission mandatory to open an issue; the core fixtures' roles lack it.
if Redmine::Plugin.installed?(:redmine_view_issue_description)
  class ActiveSupport::TestCase
    setup do
      Role.all.each { |role| role.add_permission!(:view_issue_description) }
    end
  end
end
