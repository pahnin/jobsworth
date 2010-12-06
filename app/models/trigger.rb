# encoding: UTF-8
class Trigger < ActiveRecord::Base
  belongs_to :company
  belongs_to :task_filter
  validates_presence_of :company
  validates_presence_of :fire_on

  attr_protected :company_id

  attr_accessor :trigger_type, :count, :period, :tz

  # Fires any triggers that apply to the given task and
  # fire_on time (create, update, etc)
  def self.fire(task, fire_on)
    triggers = task.company.triggers.where(:fire_on => "1")
    match = "tasks.id = #{ task.id }"

    triggers.each do |trigger|
      if trigger.task_filter
        trigger.task_filter.user = task.creator if task.creator
        apply = (trigger.task_filter.count(match) > 0)
      else
        apply = true
      end
      trigger.action.execute(:task=>task, :days=>3) if (apply && trigger.action.name=="Set due date")
    end
  end

  def action
    Action.find(action_id)
  end

  def action=(id_or_object)
    self.action_id= id_or_object.is_a?(Action) ? id_or_object.id : id_or_object.to_i
  end

  def task_filter_name
    task_filter.nil? ? "None" : task_filter.name
  end

  def event_name
    Event.find(fire_on.to_i).name
  end
end

# == Schema Information
#
# Table name: triggers
#
#  id             :integer(4)      not null, primary key
#  company_id     :integer(4)
#  task_filter_id :integer(4)
#  fire_on        :text
#  action         :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

