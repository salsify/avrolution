# frozen_string_literal: true

require 'rake'

shared_context "rake setup" do
  let(:rake) { Rake::Application.new }
  let(:task) { rake[task_name] }

  before do
    Rake.application = rake
    Rake.application.rake_require(task_path, $LOAD_PATH, [])
    Rake::Task.define_task(:environment)
  end
end
