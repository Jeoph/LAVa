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

  def test_associate_lessons_with_readings_and_destroy_readings_with_lessons
    l = Lesson.create(name: "Defense Against Ruby Black Magic")
    r1 = Reading.create(caption: "Do You Believe In Magic?", url: "http://gilesbowkett.blogspot.com/2009/07/do-you-believe-in-magic.html")
    r2 = Reading.create(caption: "Why Ruby on Rails won't become mainstream", url: "http://beust.com/weblog/2006/04/06/why-ruby-on-rails-wont-become-mainstream/")
    l.readings << r1
    l.readings << r2
    assert_equal [r1, r2], l.readings
    l.destroy
    assert l.destroyed?
    assert r1.destroyed?
    # assert l.where(id: r1.id).empty?
  end

  def test_associate_lessons_with_courses_and_destroy_lessons_with_courses
    c = Course.create(name: "A Ruby Is Not A Gem")
    l1 = Lesson.create(name: "Defense Against Ruby Black Magic")
    l2 = Lesson.create(name: "The History of Introverts Creating New Ways To Avoid Direct Contact: Computing Languages")
    c.lessons << l1
    c.lessons << l2
    assert_equal [l1, l2], c.lessons
    c.destroy
    assert c.destroyed?
    assert l1.destroyed?
    # assert Course.where(id: l1.id).empty?
  end

  def test_associate_courses_with_course_instructors_but_not_destroy_with_course_instructors
    course = Course.create(name: "A Ruby Is Not A Gem")
    i = CourseInstructor.create()
    course.course_instructors << i
    assert_equal [i], course.course_instructors
    assert_raises do course.destroy end
  end

  def test_associate_lessons_with_in_class_assignments
    skip
    l = Lesson.create(name: "Defense Against Ruby Black Magic")
    a = Assignment.create(name: "WTF Ruby?")
    l.assignments << a
    assert Lesson.in_class_assignments.find(a.in_class_assignment_id)
  end

  def test_course_has_many_readings
    c = Course.create(name: "A Ruby Is Not A Gem")
    l = Lesson.create(name: "Defense Against Ruby Black Magic")
    c.lessons << l
    r1 = Reading.create(caption: "Do You Believe In Magic?", url: "http://gilesbowkett.blogspot.com/2009/07/do-you-believe-in-magic.html")
    r2 = Reading.create(caption: "Why Ruby on Rails won't become mainstream", url: "http://beust.com/weblog/2006/04/06/why-ruby-on-rails-wont-become-mainstream/")
    l.readings << r1
    l.readings << r2
    assert_equal [r1, r2], c.readings
  end

  def test_school_must_have_name
    s1 = School.create(name: "Introverts Unite")
    s2 = School.create()
    assert School.find(s1.id)
    refute School.exists?(s2.id)
  end

  def test_terms_must_have_attributes
    s = School.create(name: "Introverts Unite")
    fall = Term.create(name: "Fall")
    spring = Term.create(name: "Spring", starts_on: 2016/2/1, ends_on: 2016/4/22, school_id: s.id)
    assert Term.find(spring.id)
    refute Term.exists?(fall.id)
  end

  # def test_user_must_have_attributes
  #   u1 = User.create(first_name: "George Michael", last_name: "Bluth")
  #   u2 = User.create(first_name: "Michael", last_name: "Bluth", email: "gobsuxors@gmail.com")
  #   assert User.find(u2.id)
  #   refute User.exists?(u1.id)
  # end
  #
  # def test_user_email_unique_required
  #   u1 = User.create(first_name: "Tobias", last_name: "Funke", email: "2blu4u@gmail.com")
  #   u2 = User.create(first_name: "George Michael", last_name: "Bluth", email: "2blu4u@gmail.com")
  #   assert User.find(u1.id)
  #   refute User.exists?(u2.id)
  # end
  #
  # def test_user_email_format_appropriate
  #   u1 = User.create(first_name: "Tobias", last_name: "Funke", email: "actorz4ever@gmail.com")
  #   u2 = User.create(first_name: "George Michael", last_name: "Bluth", email: "Y@LO@gmail.com")
  #   assert User.find(u1.id)
  #   refute User.exists?(u2.id)
  # end
  #
  # def test_user_photo_url_start_correctly
  #   u1 = User.create(first_name: "Tobias", last_name: "Funke", email: "no.naked@gmail.com", photo_url: "https://s-media-cache-ak0.pinimg.com/564x/28/54/40/285440d2714800f99169e8b3ac49969e.jpg")
  #   u2 = User.create(first_name: "George Michael", last_name: "Bluth", email: "cuzinsluveachother@gmail.com", photo_url: "www.bananagrandstanding.jpg")
  #   assert User.find(u1.id)
  #   refute User.exists?(u2.id)
  # end

  def test_assignment_has_attributes
    c = Course.create(name: "A Ruby Is Not A Gem")
    a1 = Assignment.create(name: "What Ruby?")
    a2 = Assignment.create(course_id: c.id, name: "WTF Ruby?", percent_of_grade: 0.2)
    assert Assignment.find(a2.id)
    refute Assignment.exists?(a1.id)
  end
end


# Person B:

# * Associate `lessons` with their `in_class_assignments` (both directions).
# * Validate that Assignments have a `course_id`, `name`, and `percent_of_grade`.
# * Validate that the Assignment `name` is unique within a given `course_id`.
#
# Don't forget to write tests for each of these before coding them!
#
