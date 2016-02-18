# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end

  def test_associate_lessons_with_readings
    l = Lesson.create(name: "Defense Against Ruby Black Magic")
    r1 = Reading.create(caption: "Do You Believe In Magic?", url: "http://gilesbowkett.blogspot.com/2009/07/do-you-believe-in-magic.html")
    r2 = Reading.create(caption: "Why Ruby on Rails won't become mainstream", url: "http://beust.com/weblog/2006/04/06/why-ruby-on-rails-wont-become-mainstream/")
    l.readings << r1
    l.readings << r2
    assert_equal [r1, r2], l.readings
    l.destroy
    assert Lesson.where(id: r1.id).empty?
  end







end


# Person B:

# * Associate `lessons` with `readings` (both directions).  When a lesson is destroyed, its readings should be automatically destroyed.
# * Associate `lessons` with `courses` (both directions).  When a course is destroyed, its lessons should be automatically destroyed.
# * Associate `courses` with `course_instructors` (both directions).  If the course has any students associated with it, the course should not be deletable.
# * Associate `lessons` with their `in_class_assignments` (both directions).
# * Set up a Course to have many `readings` through the Course's `lessons`.
# * Validate that Schools must have `name`.
# * Validate that Terms must have `name`, `starts_on`, `ends_on`, and `school_id`.
# * Validate that the User has a `first_name`, a `last_name`, and an `email`.
# * Validate that the User's `email` is unique.
# * Validate that the User's `email` has the appropriate form for an e-mail address.  Use a regular expression.
# * Validate that the User's `photo_url` must start with `http://` or `https://`.  Use a regular expression.
# * Validate that Assignments have a `course_id`, `name`, and `percent_of_grade`.
# * Validate that the Assignment `name` is unique within a given `course_id`.
#
# Don't forget to write tests for each of these before coding them!
#
